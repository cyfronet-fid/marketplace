# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Filterable
  include Service::Searchable
  include Service::Categorable
  include Service::Autocomplete

  def index
    if params["service_id"].present?
      redirect_to Service.find(params["service_id"])
    end
    filtered = filter(scope)
    from_category = category_records(filtered)
    from_search = search(from_category)

    @services = from_search
    @highlights = highlights(from_search)
  end

  def show
    @service = Service.
               includes(:offers, related_services: :providers).
               friendly.find(params[:id])
    authorize @service
    @offers = policy_scope(@service.offers)
    @related_services = @service.related_services

    @service_opinions = ServiceOpinion.joins(project_item: :offer).
                        where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
  end

  private

    def scope
      policy_scope(Service).with_attached_logo
    end
end
