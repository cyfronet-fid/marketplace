# frozen_string_literal: true

class ProjectItemsController < ApplicationController
  before_action :authenticate_user!

  def show
    @project_item = ProjectItem.joins(:service, project: :user).
                    find(params[:id])

    authorize(@project_item)

    @question = ProjectItem::Question.new(project_item: @project_item)
  end

  def new
    @projects = policy_scope(Project)
    @project_item = ProjectItem.new(service: selected_service)
    authorize(@project_item)
  end

  def create
    delete_project_item_from_session

    if project_item_template.project
      authorize(project_item_template)
      project_item = ProjectItem::Create.new(project_item_template).call

      if project_item.persisted?
        redirect_to project_item_path(project_item)
      else
        create_error(project_item)
      end
    else
      project_item_template.valid?
      create_error(project_item_template)
    end
  end

  private

    def project_item_template
      @new_project_item ||= ProjectItem.new(permitted_attributes(ProjectItem))
    end

    def delete_project_item_from_session
      session.delete(:project_item_item)
    end

    def selected_service
      @selected_service ||=
        Service.find_by(id: session[:project_item]["service_id"])
    end

    def create_error(project_item)
      @project_item = project_item
      @projects = policy_scope(Project)

      render :new, status: :bad_request
    end
end
