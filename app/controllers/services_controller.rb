# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Categorable
  include Service::Autocomplete
  include Service::Comparison
  include Service::Recommendable

  before_action :sort_options
  before_action :load_query_params_from_session, only: :index

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def index
    if params["object_id"].present?
      case params["type"]
      when "provider"
        redirect_to provider_path(
                      Provider.friendly.find(params["object_id"]),
                      q: params["q"],
                      anchor: ("offer-#{params["anchor"]}" if params["anchor"].present?)
                    )
      when "service"
        redirect_to service_path(
                      Service.friendly.find(params["object_id"]),
                      q: params["q"],
                      anchor: ("offer-#{params["anchor"]}" if params["anchor"].present?)
                    )
      when "datasource"
        redirect_to datasource_path(Datasource.friendly.find(params["object_id"]), q: params["q"])
      end
    end
    subgroup_quantity = 5
    additionals_size =
      if (Service.published.horizontal.size.zero? && Datasource.visible.horizontal.size.zero?) || params[:q].present? ||
           active_filters.size.positive? || @category
        0
      else
        per_page / subgroup_quantity
      end
    @presentable, @services, @offers =
      search(scope, only_visible: true, datasource_scope: datasource_scope, additionals_size: additionals_size)
    @horizontal_services = horizontal_services(@presentable, additionals_size)
    begin
      @pagy = Pagy.new_from_searchkick(@presentable, items: per_page(additionals_size))
    rescue Pagy::OverflowError
      params[:page] = 1
      @presentable, @services, @offers = search(scope, only_visible: true, datasource_scope: datasource_scope)
      @pagy = Pagy.new_from_searchkick(@presentable, page: params[:page], items: params[:per_page])
    end
    @presentable = presentable
    @highlights = highlights(@presentable)
    @recommended_services = fetch_recommended
    @favourite_services =
      current_user&.favourite_services || Service.where(slug: Array(cookies[:favourites]&.split("&") || []))
  end

  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def show
    @service = Service.includes(:offers).friendly.find(params[:id])

    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"))
    @offers = policy_scope(@service.offers.published).order(:created_at).select { |o| o.bundle? == false }
    @bundles = policy_scope(@service.offers.published).order(:created_at).select(&:bundle?)
    @similar_services = fetch_similar(@service.id, current_user&.id)
    @similar_services_title = "Similar services"
    @related_services = @service.target_relationships
    @related_services_title = "Suggested compatible resources"

    @service_opinions = ServiceOpinion.joins(project_item: :offer).where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
    @favourite_services =
      current_user&.favourite_services || Service.where(slug: Array(cookies[:favourites]&.split("&") || []))
    if current_user&.executive?
      @client = @client&.credentials&.expires_at.blank? ? Google::Analytics.new : @client
      @analytics = Analytics::PageViewsAndRedirects.new(@client).call(request.path)
    end
  end

  private

  def sort_options
    @sort_options = [
      ["by name A-Z", "sort_name"],
      ["by name Z-A", "-sort_name"],
      # ["by rate 1-5", "rating"],
      # ["by rate 5-1", "-rating"],
      ["Best match", "_score"]
    ]
  end

  def scope
    policy_scope(Service).with_attached_logo
  end

  def provider_scope
    policy_scope(Provider).with_attached_logo
  end

  def datasource_scope
    policy_scope(Datasource).with_attached_logo
  end

  def presentable
    if @horizontal_services.size.zero? || active_filters.size.positive? || params[:q] || @category
      @presentable
    else
      @presentable
        .each_slice(per_page(@horizontal_services.size) / @horizontal_services.size)
        .zip(@horizontal_services)
        .flatten
    end
  end

  def horizontal_services(presentable, limit)
    service_ids = presentable.select { |p| p.is_a?(Service) }.map(&:id)
    datasource_ids = presentable.select { |p| p.is_a?(Datasource) }.map(&:id)
    [
      Service.published.horizontal.reject { |s| service_ids.include? s.id },
      Datasource.visible.horizontal.reject { |d| datasource_ids.include? d.id }
    ].flatten.sample(limit)
  end
end
