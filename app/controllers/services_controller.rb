# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Categorable
  include Service::Sortable
  include Paginable

  def index
    @services = paginate(category_records.order(ordering))

    @filters = visible_filters
    @active_filters = active_filters
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
end
