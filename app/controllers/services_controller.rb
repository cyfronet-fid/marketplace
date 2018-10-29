# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Sortable
  include Paginable

  def index
    @services = paginate(records.order(ordering))
    @subcategories = @root_categories
  end

  def show
    @service = Service.find(params[:id])
    @service_opinions = ServiceOpinion.joins(project_item: :offer).
                        where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
    @related_services = @service.related_services.includes(:provider)
  end
end
