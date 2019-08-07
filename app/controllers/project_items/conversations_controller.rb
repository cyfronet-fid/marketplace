# frozen_string_literal: true

class ProjectItems::ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authorize_project_item!

  def show
    @message = Message.new(messageable: @project_item)
    @messages = (@project_item.messages + @project_item.statuses).sort_by(&:updated_at)

    load_project
  end

  def create
    @message = Message.
                new(permitted_attributes(Message).
                merge(author: current_user, messageable: @project_item))

    if Message::Create.new(@message).call
      flash[:notice] = "Message sent successfully"
      redirect_to project_item_conversation_path(@project_item)
    else
      load_project
      @messages = @project_item.messages
      render "project_items/conversations/show", status: :bad_request
    end
  end

  private

    def load_project
      @project = @project_item.project
      @projects = policy_scope(Project).order(:name)
    end

    def load_and_authorize_project_item!
      @project_item = ProjectItem.find(params[:project_item_id])
      authorize(@project_item, :show?)
    end
end
