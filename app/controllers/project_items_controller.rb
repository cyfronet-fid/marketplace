# frozen_string_literal: true

class ProjectItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_messageable, only: [:message]

  def show
    @project_item = ProjectItem.joins(offer: :service, project: :user).
                    find(params[:id])

    authorize(@project_item)

    @message = Message.new(messageable: @project_item)
    @messages = (@project_item.messages + @project_item.statuses).sort { |p, c| c.updated_at <=> p.updated_at }
  end


  def message
    @message = Message.
                new(permitted_attributes(Message).
                    merge(author: current_user,
                          messageable: @messageable))

    authorize(@messageable)

    if Message::Create.new(@message).call
      flash[:notice] = "Message sent successfully"
      redirect_to project_item_path(@messageable)
    else
      flash[:alert] = "Error ocured while sanding message"
      redirect_to project_item_path(@messageable)
    end
  end
  private

    def load_messageable
      @messageable = ProjectItem.find(params[:project_item_id])
    end
end
