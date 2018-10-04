# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Sortable
  include Paginable

  def index
    @services = paginate(records.order(ordering))
    @subcategories = @root_categories
    @providers = Provider.all
  end

  def show
    @service = Service.
               includes(:offers, related_services: :provider).
               find(params[:id])

    @offers = @service.offers
    @related_services = @service.related_services

    @service_opinions = ServiceOpinion.joins(project_item: :offer).
                        where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
  end
end
