# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_and_authorize, only: %i[show edit update destroy]

  IGNORED_ATTRIBUTES = %w[id name issue_key issue_status issue_key].freeze

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
  end

  def create
    @project = Project.new(permitted_attributes(Project).merge(user: current_user, status: :active))

    respond_to do |format|
      form_valid = @project.valid? & verify_recaptcha(model: @project, attribute: :verified_recaptcha)
      if form_valid && Project::Create.new(@project).call
        format.html { redirect_to project_path(@project), notice: "Project successfully created" }
        format.turbo_stream { flash.now[:notice] = "Project successfully created" }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if Project::Update.new(@project, permitted_attributes(@project)).call
      redirect_to project_path(@project), notice: "Project updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    if Project::Destroy.new(@project).call
      redirect_to projects_path, notice: "Project removed successfully"
    else
      redirect_to project_path(@project), alert: "Unable to remove project"
    end
  end

  private

  def new_record
    Project.new(attributes.merge(status: :active))
  end

  def attributes
    source = params[:source] && current_user.projects.find_by(id: params[:source])
    if source
      source
        .attributes
        .reject { |a| IGNORED_ATTRIBUTES.include?(a) }
        .merge(user: current_user, scientific_domain_ids: source.scientific_domain_ids)
    else
      { user: current_user }
    end
  end

  def find_and_authorize
    @project = Project.find(params[:id])
    authorize(@project)
  end
end
