# frozen_string_literal: true

class ProjectItemsController < ApplicationController
  before_action :authenticate_user!

  def show
    @projects = policy_scope(Project).order(:name)
    @project_item = ProjectItem.joins(offer: :service, project: :user).
                    find(params[:id])
    @project = @project_item.project

    authorize(@project_item)

    @question = ProjectItem::Question.new(project_item: @project_item)
  end
end
