# frozen_string_literal: true

class ProjectItems::QuestionsController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to project_item_path(id: params[:project_item_id])
  end

  def create
    @project_item = ProjectItem.find(params[:project_item_id])
    @question = ProjectItem::Question.
                new(permitted_attributes(ProjectItem::Question).
                    merge(author: current_user, project_item: @project_item))

    authorize(@question)

    if ProjectItem::Question::Create.new(@question).call
      redirect_to project_item_path(@project_item)
    else
      render "project_items/show"
    end
  end
end
