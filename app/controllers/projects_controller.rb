# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!

  def index
    @projects = policy_scope(Project).order(:name).eager_load(:project_items)
    @projects = @projects.where("project_items.status = ?",
                                params[:status]) if filterable?(params[:status])
  end

  def show
    @project = Project.find(params[:id])
    authorize(@project)

    respond_to do |format|
      format.json do
        render status: :ok, json: {
          name: @project.name,
          reason_for_access: @project.reason_for_access,
          customer_typology: @project.customer_typology,
          user_group_name: @project.user_group_name,
          project_name: @project.project_name,
          project_website_url: @project.project_website_url,
          company_name: @project.company_name,
          company_website_url: @project.company_website_url
        }
      end
    end
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
    def filterable?(param)
      (param.present? && ProjectItem.statuses.has_key?(param))
    end

    def render_modal_form
      render "layouts/show_modal",
              locals: {
                title: "New project",
                action_btn: "Create new project",
                form: "projects/form"
              }
    end
end
