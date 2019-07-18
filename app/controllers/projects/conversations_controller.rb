# frozen_string_literal: true

class Projects::ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authorize_project!

  def show
    @projects = policy_scope(Project).order(:name)
    @messages = @project.messages.order("created_at ASC")
    @message = Message.new(messageable: @project)
  end

  def create
    @message = Message.
                new(permitted_attributes(Message).
                    merge(author: current_user, messageable: @project))

    if Message::Create.new(@message).call
      flash[:notice] = "Message sent successfully"
      redirect_to project_conversation_path(@project)
    else
      @messages = @project.messages
      @projects = policy_scope(Project).order(:name)
      render :show, status: :bad_request
    end
  end

  private

    def load_and_authorize_project!
      @project = Project.find(params[:project_id])
      authorize(@project, :show?)
    end
end
