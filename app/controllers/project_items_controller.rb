# frozen_string_literal: true

class ProjectItemsController < ApplicationController
  before_action :authenticate_user!

  def show
    @project_item = ProjectItem.joins(offer: :service, project: :user).find(params[:id])

    authorize(@project_item)

    @projects = policy_scope(Project).order(:name)
    @project = @project_item.project
  end
end
