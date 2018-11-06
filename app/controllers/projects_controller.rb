# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!

  def index
    @projects = policy_scope(Project).order(:name).includes(:project_items)
  end

  def new
    respond_to do |format|
      format.js do
        @project = Project.new(user: current_user)
        render_modal_form
      end
    end
  end

  def create
    respond_to do |format|
      format.js do
        @project = Project.new(permitted_attributes(Project).
                               merge(user: current_user))

        if @project.save
          render :show
        else
          render_modal_form
        end
      end
    end
  end

  private

    def render_modal_form
      render "layouts/show_modal",
              locals: {
                title: "New project",
                action_btn: "Create new project",
                form: "projects/form"
              }
    end
end
