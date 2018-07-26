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
    @service_opinions = ServiceOpinion.joins(:project_item).where(project_items: { service: @service })
  end

  def active?(service)
    # user can have only one open_access service order with status ready
    service.open_access &&
    current_user &&
    ProjectItem.find_by(service: service.id,
                                               project: current_user.projects,
                                         status: [:created, :ready])
  end
end
