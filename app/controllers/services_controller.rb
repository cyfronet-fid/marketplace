# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Filterable
  include Service::Searchable
  include Service::Categorable
  include Service::Sortable

  def index
    filtered = filter(scope)
    from_category = category_records(filtered)

    @services = search(order(from_category))
  end

  def show
    @service = Service.
               includes(:offers, related_services: :providers).
               friendly.find(params[:id])
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
