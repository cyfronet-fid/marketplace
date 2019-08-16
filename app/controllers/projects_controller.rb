# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  def index
    @projects = policy_scope(Project)
    redirect_to @projects.first if @projects.count.positive?
  end

  def show
    respond_to do |format|
      format.json do
        render status: :ok, json: {
          additional_information: @project.additional_information,
          name: @project.name,
          reason_for_access: @project.reason_for_access,
          customer_typology: t(@project.customer_typology, scope: [:project, :customer_typology]),
          research_areas: @project.research_areas,
          user_group_name: @project.user_group_name,
          country_of_origin: @project.country_of_origin,
          countries_of_partnership: @project.countries_of_partnership,
          project_name: @project.project_name,
          project_website_url: @project.project_website_url,
          company_name: @project.company_name,
          company_website_url: @project.company_website_url,
          email: @project.email,
          department: @project.department,
          organization: @project.organization,
          webpage: @project.webpage
        }
      end
      format.html do
        @projects = policy_scope(Project).order(:name)
      end
    end
  end

  def new
    @project = new_record

    respond_to do |format|
      format.html
      format.js { render_modal_form }
    end
  end

  def create
    @project = Project.new(permitted_attributes(Project).
                           merge(user: current_user, status: :active))

    respond_to do |format|
      if Project::Create.new(@project).call
        format.html { redirect_to project_path(@project) }
        format.js { render :show }
      else
        format.html { render :new, status: :bad_request }
        format.js { render_modal_form }
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
    if Project::Destroy.new(@project).call
      redirect_to projects_path, notice: "Project destroyed"
    else
      redirect_to project_path(@project), alert: "Unable to remove project"
    end
  end

  private

    def new_record
      Project.new(attributes.merge(status: :active))
    end

    IGNORED_ATTRIBUTES = ["id", "name", "issue_key", "issue_status", "issue_key"]
    def attributes
      source = params[:source] && current_user.projects.find_by(id: params[:source])
      if source
        source.attributes.
          reject { |a| IGNORED_ATTRIBUTES.include?(a) }.
          merge(user: current_user)
      else
        { user: current_user }
      end
    end

    def render_modal_form
      @show_as_modal = true
      render "layouts/show_modal",
              locals: {
                title: "New project",
                action_btn: t("project.buttons.create"),
                form: "projects/form"
              }
    end

    def find_and_authorize
      @project = Project.find(params[:id])
      authorize(@project)
    end
end
