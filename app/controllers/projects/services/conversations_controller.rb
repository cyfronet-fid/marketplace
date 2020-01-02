# frozen_string_literal: true

class Projects::Services::ConversationsController < ApplicationController
  include ProjectItem::Authorize

  def show
    @message = Message.new(messageable: @project_item)

    load_messages
    load_projects
  end

  def create
    @message = Message.
                new(permitted_attributes(Message).
                merge(author: current_user, messageable: @project_item))

    if Message::Create.new(@message).call
      flash[:notice] = "Message sent successfully"
      redirect_to project_service_conversation_path(@project, @project_item)
    else
      load_messages
      load_projects
      render "show", status: :bad_request
    end
  end

  private
    def load_projects
      @projects = policy_scope(Project).order(:name)
    end

    def load_messages
      @messages = @project_item.messages.order(:updated_at)
    end
end
