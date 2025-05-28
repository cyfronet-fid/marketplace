# frozen_string_literal: true

class ServicesController < ApplicationController
  EXTERNAL_SEARCH_ENABLED = Mp::Application.config.enable_external_search

  include Service::Searchable
  include Service::Categorable
  include Service::Autocomplete
  include Service::Comparison
  include Service::Monitorable
  include Service::Recommendable

  before_action :sort_options
  before_action :load_query_params_from_session, only: :index

  # rubocop:disable Metrics/AbcSize
  def index
    search_base_url = Mp::Application.config.search_service_base_url
    redirect_to search_base_url + "/search/service?q=*", allow_other_host: true if external_search_enabled

    if params["object_id"].present?
      case params["type"]
      when "provider"
        redirect_to provider_path(
                      Provider.friendly.find(params["object_id"]),
                      q: params["q"],
                      anchor: ("offer-#{params["anchor"]}" if params["anchor"].present?)
                    )
      when "service"
        redirect_to service_offers_path(
                      Service.friendly.find(params["object_id"]),
                      q: params["q"],
                      anchor: ("offer-#{params["anchor"]}" if params["anchor"].present?)
                    )
      end
    end
    subgroup_quantity = 5
    additionals_size = hide_horizontals? ? 0 : (per_page / subgroup_quantity)
    @services, @offers = search(scope, additionals_size: additionals_size)
    @horizontals = horizontals(@services, additionals_size)
    @presentable = presentable
    begin
      @pagy = Pagy.new_from_searchkick(@services, items: per_page(additionals_size))
    rescue Pagy::OverflowError
      params[:page] = 1
      @services, @offers = search(scope)
      @pagy = Pagy.new_from_searchkick(@services, items: params[:per_page])
    end
    @highlights = highlights(@services)
    @recommended_services = fetch_recommended
    @favourite_services =
      current_user&.favourite_services || Service.where(slug: Array(cookies[:favourites]&.split("&") || []))
  end

  # rubocop:enable Metrics/AbcSize

  def show
    @service = Service.includes(:offers).friendly.find(params[:id])
    @service.store_analytics unless Mp::Application.config.analytics_enabled
    @service.monitoring_status = fetch_status(@service.pid)

    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"))
    @offers = policy_scope(@service.offers.inclusive).order(:iid)
    @bundles = policy_scope(@service.bundles.published).order(:iid)
    @bundled = bundled
    @similar_services = fetch_similar(@service.id, current_user&.id)
    @related_services = @service.related_services

    @service_opinions = ServiceOpinion.joins(project_item: :offer).where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
    @favourite_services =
      current_user&.favourite_services || Service.where(slug: Array(cookies[:favourites]&.split("&") || []))
    override_user_action_info
  end

  private

  def override_user_action_info
    # Overrides for user actions when the client is being redirected from outside

    if !params[:client_uid].nil? && validate_uuid_format(params[:client_uid])
      cookies[:client_uid] = { value: params[:client_uid], expires: 1.week.from_now }
    end

    @source_id_override = params[:source_id] if !params[:source_id].nil? && validate_uuid_format(params[:source_id])
  end

  def sort_options
    @sort_options = [
      ["by name A-Z", "sort_name"],
      ["by name Z-A", "-sort_name"],
      ["by rate 1-5", "rating"],
      ["by rate 5-1", "-rating"],
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
    if hide_horizontals?(init: false)
      @services
    else
      @services.each_slice(per_page(@horizontals.size) / @horizontals.size).zip(@horizontals).flatten
    end
  end

  def horizontals(services, limit)
    service_ids = services.map(&:id)
    Service.published.horizontal.reject { |s| service_ids.include? s.id }.sample(limit)
  end

  def hide_horizontals?(init: true)
    empty_listed = init ? Service.published.horizontal.empty? : @horizontals.empty?
    empty_listed || active_filters.size.positive? || params[:q].present? || @category.present?
  end

  def external_search_enabled
    EXTERNAL_SEARCH_ENABLED
  end
end
