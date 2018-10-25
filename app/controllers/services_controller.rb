# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Sortable
  include Paginable

  def index
    @services = paginate(records.order(ordering))
    @subcategories = Category.roots
  end

  def show
    @service = Service.find(params[:id])
    @service_opinions = ServiceOpinion.joins(project_item: :offer).
                        where(offers: { service_id: @service })
    @question = Service::Question.new(service: @service)
  end
end
