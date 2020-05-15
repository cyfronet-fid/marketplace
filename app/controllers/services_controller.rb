# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Categorable
  include Service::Autocomplete
  include Service::Comparison

  before_action :sort_options

  def index
    if params["service_id"].present?
      redirect_to service_path(Service.find(params["service_id"]),
                               anchor: ("offer-#{params["anchor"]}" if params["anchor"].present?))
    end
    @services, @offers = search(scope)
    @highlights = highlights(@services)
  end

  def show
    @service = Service.
               includes(:offers, related_services: :providers).
               friendly.find(params[:id])
    authorize @service
    @offers = policy_scope(@service.offers).order(:created_at)
    @related_services = @service.related_services

    @service_opinions = ServiceOpinion.joins(project_item: :offer).
                        where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
    if current_user&.executive?
      @client = @client&.credentials&.expires_at.blank? ? Google::Analytics.new : @client
      @analytics = Analytics::PageViewsAndRedirects.new(@client).call(request.path)
    end
  end

  private
    def sort_options
      @sort_options = [["by name A-Z", "title"],
                       ["by name Z-A", "-title"],
                       ["by rate 1-5", "rating"],
                       ["by rate 5-1", "-rating"],
                       ["Best match", "_score"]]
    end

    def scope
      policy_scope(Service).with_attached_logo
    end
end
