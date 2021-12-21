# frozen_string_literal: true

class Projects::ArchivesController < ApplicationController
  include Project::Authorize

  def create
    authorize(@project, :archive?)
    if Project::Archive.new(@project).call
      redirect_to projects_path, notice: "Project archived"
    else
      flash[:alert] = "Project cannot be archived"
      redirect_to project_path(@project)
    end
  end
end
