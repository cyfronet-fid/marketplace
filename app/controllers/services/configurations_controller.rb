# frozen_string_literal: true

class Services::ConfigurationsController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    @projects = current_user.projects
    @project_item = ProjectItem.new(session[session_key])

    if new_open_access_service?
      set_default_project_and_to_summary!
    end
  end

  def update
    @project_item = ProjectItem.new(configuration_params)

    if @project_item.valid?
      session[session_key] = @project_item.attributes
      redirect_to service_summary_path(@service)
    else
      @projects = current_user.projects
      render :show
    end
  end

  private
    def configuration_params
      session[session_key].
        merge(permitted_attributes(ProjectItem)).
        merge(status: :created)
    end

    def default_project
      current_user.projects.find_by(name: "Services")
    end

    def new_open_access_service?
      @service.open_access && @project_item.project.blank?
    end

    def set_default_project_and_to_summary!
      @project_item.project = default_project
      @project_item.status = :created

      if @project_item.valid?
        session[session_key] = @project_item.attributes
        redirect_to service_summary_path(@service)
      end
    end
end
