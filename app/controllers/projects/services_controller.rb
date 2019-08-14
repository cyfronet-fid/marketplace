# frozen_string_literal: true

class Projects::ServicesController < ApplicationController
  include Project::Authorize

  before_action :load_projects

  def index
    @project_items = @project.project_items
  end

  def show
    @project_item = @project.project_items.
                    joins(offer: :service, project: :user).
                    find_by!(iid: params[:id])

    authorize(@project_item)
  end

  private

    def load_projects
      @projects = policy_scope(Project).order(:name)
    end
end
