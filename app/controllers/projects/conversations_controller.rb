# frozen_string_literal: true

class Projects::ConversationsController < ApplicationController
  include Project::Authorize

  def show
    @message = Message.new(messageable: @project)
    prepare_models
  end

  def create
    @message =
      Message.new(
        permitted_attributes(Message).merge(
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
      prepare_models
      render "show", status: :bad_request
    end
  end

  private

  def load_projects!
    @projects = policy_scope(Project).order(:name)
  end

  def load_messages!
    @messages = policy_scope(@project.messages).order(:created_at)
    @earliest_new_message = @project.earliest_new_message_to_user
  end

  def prepare_models
    load_projects!
    load_messages!
    @project.update(conversation_last_seen: Time.now)
  end
end
