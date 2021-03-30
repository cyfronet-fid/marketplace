# frozen_string_literal: true

class Projects::ConversationsController < ApplicationController
  include Project::Authorize

  def show
    @message = Message.new(messageable: @project)

    load_messages!
    load_projects!
  end

  def create
    @message = Message.new(
      permitted_attributes(Message)
        .merge(
          author: current_user,
          author_role: :user,
          scope: :public,
          messageable: @project
        )
    )

    if Message::Create.new(@message).call
      flash[:notice] = "Message sent successfully"
      redirect_to project_conversation_path(@project)
    else
      load_messages!
      load_projects!
      render :show, status: :bad_request
    end
  end

  private
    def load_projects!
      @projects = policy_scope(Project).order(:name)
    end

    def load_messages!
      @messages = policy_scope(@project.messages).order(:created_at)
    end
end
