# frozen_string_literal: true

class Projects::ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authorize_project!

  def index
  end

  private

    def load_and_authorize_project!
      @project = Project.find(params[:project_id])
      authorize(@project)
    end
end
