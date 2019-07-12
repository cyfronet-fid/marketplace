# frozen_string_literal: true

class Projects::ChatsController < ApplicationController
  before_action :authenticate_user!

  include Project::Authorize

  def show
    @projects = policy_scope(Project).order(:name)
  end

  private

    def load_and_authorize_project!
      @project = Project.find(params[:project_id])
      authorize(@project)
    end
end
