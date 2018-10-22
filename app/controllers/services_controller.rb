# frozen_string_literal: true

class ServicesController < ApplicationController
  include Service::Searchable
  include Service::Sortable

  def index
    @services = records.order(ordering).page(params[:page])
    @subcategories = Category.roots
  end

  def show
    @service = Service.find(params[:id])
    @service_opinions = ServiceOpinion.joins(project_item: :offer).
                        where(offers: { service_id: @service })
  end
end
