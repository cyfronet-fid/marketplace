# frozen_string_literal: true

class Projects::ArchivesController < ApplicationController
  before_action :load_and_authorize_project!

  def create
    if Project::Archive.new(@project).call
      redirect_to projects_path,
                  notice: "Project archived"
    else
      flash[:allert] = "Project cannot be archived"
      redirect_to project_path(@project)
    end
  end

  private

    def load_and_authorize_project!
      @project = Project.find(params[:project_id])
      authorize(@project, :archive?)
    end
end
