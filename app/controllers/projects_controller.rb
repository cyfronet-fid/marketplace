# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  def index
    @projects = policy_scope(Project)
    redirect_to project_services_path(@projects.first) if @projects.count.positive?
  end

  def show
    if request.xhr?
      render template: "projects/_details", locals: { project: @project }, layout: false
    else
      @projects = policy_scope(Project).order(:name)
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
      if verify_recaptcha && Project::Create.new(@project).call
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
      render "layouts/show_modal",
              locals: {
                title: "New project",
                action_btn: t("projects.buttons.create"),
                form: "projects/form",
                form_locals: { project: @project, show_as_modal: true, show_recaptcha: true }
              }
    end

    def find_and_authorize
      @project = Project.find(params[:id])
      authorize(@project)
    end
end
