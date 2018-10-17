# frozen_string_literal: true

class ProjectItems::ServiceOpinionsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_project_item, only: :create

  def new
    @project_item = ProjectItem.find(params[:project_item_id])
    @service_opinion = ServiceOpinion.new(project_item: @project_item)
    authorize(@service_opinion)
  end

  def create
    template = service_opinion_template
    authorize(template)

    @service_opinion = ServiceOpinion::Create.new(template).call
    if @service_opinion.persisted?
      redirect_to project_item_path(@project_item), notice: "Rating submitted sucessfully"
    else
      render :new, status: :bad_request
    end
  end


  private
    def find_project_item
      @project_item = ProjectItem.joins(:service).find(params[:project_item_id])
    end

    def service_opinion_template
      ServiceOpinion.new(permitted_attributes(ServiceOpinion).merge(project_item: @project_item))
    end
end
