# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Sortable
  include Paginable

  def index
    @services = paginate(records.order(ordering))

    @provider_options = provider_options
    @dedicated_for_options = dedicated_for_options
    @rating_options = rating_options
    @research_areas = ResearchArea.all
    @related_platform_options = related_platform_options
  end

  def show
    @service = Service.
               joins(:platforms).
               includes(:offers, related_services: :providers).
               friendly.find(params[:id])

    @offers = @service.offers
    @related_services = @service.related_services

    @service_opinions = ServiceOpinion.joins(project_item: :offer).
                        where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
  end
end
