# frozen_string_literal: true

class Projects::Services::ConversationsController < ApplicationController
  include ProjectItem::Authorize

  def show
    @message = Message.new(messageable: @project_item)
    prepare_models
  end

  def create
    @message =
      Message.new(
        permitted_attributes(Message).merge(
          author: current_user,
          author_role: :user,
          scope: :public,
          messageable: @project_item
        )
      )

    if Message::Create.new(@message).call
      flash[:notice] = _("Message sent successfully")
      redirect_to project_service_conversation_path(@project, @project_item)
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
    @messages = policy_scope(@project_item.messages).order(:created_at)
    @earliest_new_message = @project_item.earliest_new_message_to_user
  end

  def prepare_models
    load_projects!
    load_messages!
    @project_item.update(conversation_last_seen: Time.now)
  end
end
