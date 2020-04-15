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
    if @service_opinion.persisted?
      Matomo::SendRequestJob.perform_later(@project_item, "Rate", @service_opinion.service_rating)
      redirect_to project_service_path(@project, @project_item),
                  notice: "Rating submitted sucessfully"
    else
      render :new, status: :bad_request
    end
  end


  private
    def load_and_authorize_project_item!
      @project_item = ProjectItem.joins(:project).
                      find_by(iid: params[:service_id],
                              project_id: params[:project_id])
      @project = @project_item.project

      authorize(@project_item, :show?)
    end

    def service_opinion_template
      ServiceOpinion.new(permitted_attributes(ServiceOpinion).
                         merge(project_item: @project_item))
    end
end
