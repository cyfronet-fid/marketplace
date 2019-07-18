# frozen_string_literal: true

class ProjectItems::ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authorize_project_item!

  def create
    @message = Message.
                new(permitted_attributes(Message).
                merge(author: current_user, messageable: @project_item))

    if Message::Create.new(@message).call
      flash[:notice] = "Message sent successfully"
      redirect_to @project_item
    else
      @projects = policy_scope(Project)
      @project = @project_item.project
      @messages = @project_item.messages
      render "project_items/show", status: :bad_request
    end
  end

  private

    def load_and_authorize_project_item!
      @project_item = ProjectItem.find(params[:project_item_id])
      authorize(@project_item, :show?)
    end
end
