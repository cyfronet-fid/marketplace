# frozen_string_literal: true

class ProjectItemsController < ApplicationController
  before_action :authenticate_user!

  def index
    @project_items = policy_scope(ProjectItem)
  end

  def show
    @project_item = ProjectItem.joins(:user, :service).find(params[:id])

    authorize(@project_item)

    @question = ProjectItem::Question.new(project_item: @project_item)
  end

  def new
    @projects = current_user.projects
    @project_item = ProjectItem.new(service: selected_service)
    authorize(@project_item)
  end

  def create
    delete_project_item_from_session

    authorize(project_item_template)
    project_item = ProjectItem::Create.new(project_item_template).call

    if project_item.persisted?
      redirect_to project_item_path(project_item)
    else
      redirect_to service_path(project_item.service),
                  alert: "Unable to create service request"
    end
  end

  private

    def project_item_template
      @new_project_item ||= ProjectItem.new(permitted_attributes(ProjectItem).
                               merge(user: current_user))
    end

    def delete_project_item_from_session
      session.delete(:project_item_item)
    end

    def selected_service
      @selected_service ||=
        Service.find_by(id: session[:project_item]["service_id"])
    end
end
