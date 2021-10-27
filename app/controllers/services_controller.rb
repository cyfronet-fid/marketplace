# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Categorable
  include Service::Autocomplete
  include Service::Comparison
  include Service::Recommendable

  before_action :sort_options
  before_action :load_query_params_from_session, only: :index

  def index
    if params["object_id"].present?
      case params["type"]
      when "provider"
        redirect_to provider_path(Provider.friendly.find(params["object_id"]), q: params["q"],
                                                                               anchor: (if params["anchor"].present?
                                                                                          "offer-#{params['anchor']}"
                                                                                        end))
      when "service"
        redirect_to service_path(Service.friendly.find(params["object_id"]), q: params["q"],
                                                                             anchor: (if params["anchor"].present?
                                                                                        "offer-#{params['anchor']}"
                                                                                      end))
      end
    end
    @services, @offers = search(scope)
    @pagy = Pagy.new_from_searchkick(@services, items: params[:per_page])
    @highlights = highlights(@services)
    @recommended_services = fetch_recommended
    @favourite_services = current_user&.favourite_services || Service
                          .where(slug: Array(cookies[:favourites]&.split("&") || []))
  end

  def show
    @service = Service
               .includes(:offers, :target_relationships)
               .friendly.find(params[:id])

    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"))
    @offers = policy_scope(@service.offers.published).order(:created_at).select { |o| o.bundle? == false }
    @bundles = policy_scope(@service.offers.published).order(:created_at).select(&:bundle?)
    @related_services = @service.target_relationships
    @related_services_title = "Suggested compatible resources"

    @service_opinions = ServiceOpinion.joins(project_item: :offer)
                                      .where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
    @favourite_services = current_user&.favourite_services || Service
                          .where(slug: Array(cookies[:favourites]&.split("&") || []))
    if current_user&.executive?
      @client = @client&.credentials&.expires_at.blank? ? Google::Analytics.new : @client
      @analytics = Analytics::PageViewsAndRedirects.new(@client).call(request.path)
    end

    ab_finished(:recommendation_panel, reset: false) if params[:from_recommendation_panel]
  end

  private

  def sort_options
    @sort_options = [["by name A-Z", "sort_name"],
                     ["by name Z-A", "-sort_name"],
                     ["by rate 1-5", "rating"],
                     ["by rate 5-1", "-rating"],
                     ["Best match", "_score"]]
  end

  def scope
    policy_scope(Service).with_attached_logo
  end

  def provider_scope
    policy_scope(Provider).with_attached_logo
  end
end
