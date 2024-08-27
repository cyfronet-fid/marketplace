# frozen_string_literal: true

class Projects::Services::OpinionsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authorize_project_item!

  def new
    @service_opinion = ServiceOpinion.new(project_item: @project_item)
    authorize(@service_opinion)
  end

  def create
    template = service_opinion_template
    authorize(template)

    @service_opinion = ServiceOpinion::Create.new(template).call
    respond_to do |format|
      if @service_opinion.persisted?
        Matomo::SendRequestJob.perform_later(@project_item, "Rate", @service_opinion.service_rating)
        format.html do
          redirect_to project_service_offers_path(@project, @project_item), notice: "Rating submitted successfully"
        end
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_and_authorize_project_item!
    @project_item = ProjectItem.joins(:project).find_by(iid: params[:service_id], project_id: params[:project_id])
    @project = @project_item.project

    authorize(@project_item, :show?)
  end

  def service_opinion_template
    ServiceOpinion.new(permitted_attributes(ServiceOpinion).merge(project_item: @project_item))
  end
end
