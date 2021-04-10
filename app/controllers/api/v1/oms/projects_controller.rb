# frozen_string_literal: true

class Api::V1::Oms::ProjectsController < Api::V1::Oms::ApiController
  before_action :find_and_authorize_oms
  before_action :find_and_authorize, only: :show

  def index
    @from_id = params[:from_id].present? ? params[:from_id] : 0
    @limit = params[:limit].present? ? params[:limit] : 20
    load_projects
    render json: { projects: @projects.map { |p| OrderingApi::V1::ProjectSerializer.new(p) } }
  end

  def show
    render json: OrderingApi::V1::ProjectSerializer.new(@project).as_json
  end

  private
    def find_and_authorize
      @project = @oms.projects.find(params[:id])
      authorize @project
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Project not found" }, status: 404
    end

    def load_projects
      @projects = policy_scope(@oms.projects).where("projects.id > ?", @from_id).order("projects.id").limit(@limit)
    end
end
