# frozen_string_literal: true

class Projects::ServicesController < ApplicationController
  include Project::Authorize

  before_action :load_projects

  def index
    @project_items = @project.project_items
  end

  def show
    @project_item = ProjectItem.joins(offer: :service, project: :user).find(params[:id])
    @question = ProjectItem::Question.new(project_item: @project_item)
  end

  private

    def load_projects
      @projects = policy_scope(Project).order(:name)
    end
end
