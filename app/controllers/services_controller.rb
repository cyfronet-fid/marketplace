# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Categorable
  include Service::Autocomplete
  include Service::Comparison
  include Service::Monitorable
  include Service::Recommendable

  before_action :sort_options
  before_action :load_query_params_from_session, only: :index

  def index
    search_base_url = Mp::Application.config.search_service_base_url
    redirect_to search_base_url + "/search/service?q=*", allow_other_host: true if external_search_enabled?

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
    @services, @offers = search(scope, additionals_size: 0)
    @horizontals = []
    @presentable = @services
    begin
      @pagy = Pagy.new_from_searchkick(@services, items: per_page)
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

  def show
    @service = Service.includes(:offers).friendly.find(params[:id])
    @service.store_analytics unless Mp::Application.config.analytics_enabled
    @service.monitoring_status = fetch_status(@service.pid)

    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"))
    @offers = policy_scope(@service.offers.inclusive).order(:iid)
    @bundles = policy_scope(@service.bundles.published).order(:iid)
    @bundled = bundled
    @similar_services = fetch_similar(@service.id, current_user&.id)
    @related_services = []

    @service_opinions =
      ServiceOpinion.joins(project_item: :offer).where(offers: { orderable_type: "Service", orderable_id: @service.id })
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
end
