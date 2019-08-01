# frozen_string_literal: true

class Projects::AddsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authorize_project!

  def create
    session[:selected_project] = @project.id

    redirect_to services_path
  end

  private

    def load_and_authorize_project!
      @project = Project.find(params[:project_id])
      authorize(@project, :show?)
    end
end
