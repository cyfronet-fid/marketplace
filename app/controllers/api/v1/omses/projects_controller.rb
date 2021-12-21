# frozen_string_literal: true

class Api::V1::OMSes::ProjectsController < Api::V1::ApplicationController
  before_action :find_and_authorize_oms
  before_action :validate_from_id, only: :index
  before_action :validate_limit, only: :index
  before_action :load_projects, only: :index
  before_action :find_and_authorize, only: :show

  def index
    render json: { projects: @projects.map { |p| Api::V1::ProjectSerializer.new(p) } }
  end

  def show
    render json: Api::V1::ProjectSerializer.new(@project).as_json
  end

  private

  def load_projects
    @projects = policy_scope(@oms.projects).where("projects.id > ?", @from_id).order("projects.id").limit(@limit)
  end

  def find_and_authorize
    @project = @oms.projects.find(params[:id])
    authorize @project
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: 404
  end
end
