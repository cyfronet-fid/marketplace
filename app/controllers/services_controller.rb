# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Sortable
  include Paginable

  def index
    @services = paginate(records.order(ordering))

    @provider_options = options_providers
    @target_groups_options = options_target_groups
    @rating_options = options_rating
    @research_areas = options_research_area
    @related_platform_options = options_related_platforms
    @tag_options = options_tag
    @active_filters = active_filters
  end

  def show
    @service = Service.
               includes(:offers, related_services: :providers).
               friendly.find(params[:id])
    @offers = @service.offers
    @related_services = @service.related_services

    @service_opinions = ServiceOpinion.joins(project_item: :offer).
                        where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
  end
end
