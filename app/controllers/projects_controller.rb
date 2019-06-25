# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  def index
    @projects = policy_scope(Project).order(:name).eager_load(:project_items)
  end

  def show
    respond_to do |format|
      format.json do
        render status: :ok, json: {
          additional_information: @project.additional_information,
          name: @project.name,
          reason_for_access: @project.reason_for_access,
          customer_typology: t(@project.customer_typology, scope: [:project, :customer_typology]),
          user_group_name: @project.user_group_name,
          project_name: @project.project_name,
          project_website_url: @project.project_website_url,
          company_name: @project.company_name,
          company_website_url: @project.company_website_url
        }
      end
      format.html
    end
  end

  def new
    @project = Project.new(user: current_user)

    respond_to do |format|
      format.html
      format.js do
        render_modal_form
      end
    end
  end

  def create
    @project = Project.new(permitted_attributes(Project).
                           merge(user: current_user))

    respond_to do |format|
      format.html do
        if @project.save
          Project::Create.new(@project).call
          redirect_to projects_path
        else
          render :new, status: :bad_request
        end
      end

      format.js do
        if @project.save
          Project::Create.new(@project).call
          render :show
        else
          render_modal_form
        end
      end
    end
  end

  def edit
  end

  def update
    if Project::Update.new(@project, permitted_attributes(@project)).call
      redirect_to project_path(@project),
                  notice: "Project updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    Project::Destroy.new(@project).call
    redirect_to projects_path,
                notice: "Project destroyed"
  end

  private

    def render_modal_form
      @show_as_modal = true
      render "layouts/show_modal",
              locals: {
                title: "New project",
                action_btn: "Create new project",
                form: "projects/form"
              }
    end

    def find_and_authorize
      @project = Project.find(params[:id])
      authorize(@project)
    end
end
