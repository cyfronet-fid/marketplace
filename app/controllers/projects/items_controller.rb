# frozen_string_literal: true

class Projects::ItemsController < ApplicationController
  before_action :authenticate_user!

  def show
    @project_item = ProjectItem.joins(offer: :service, project: :user).
                    find(params[:id])

    authorize(@project_item)

    @projects = policy_scope(Project).order(:name)
    @project = @project_item.project
    @message = Message.new(messageable: @project_item)
    @messages = (@project_item.messages + @project_item.statuses).sort_by(&:updated_at)
  end
end
