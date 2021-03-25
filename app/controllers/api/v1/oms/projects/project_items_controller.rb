# frozen_string_literal: true

class Api::V1::Oms::Projects::ProjectItemsController < Api::V1::Oms::ApiController
  before_action :find_project
  before_action :find_and_authorize, only: [:show, :update]
  before_action :validate_payload, only: :update

  def index
    # TODO: Obfuscate user secrets
    @from_id = params[:from_id].present? ? params[:from_id] : 0
    @limit = params[:limit].present? ? params[:limit] : 20
    load_project_items
    render json: { project_items: @project_items.map { |pi| OrderingApi::V1::ProjectItemSerializer.new(pi) } }
  end

  def show
    # TODO: Obfuscate user secrets
    render json: OrderingApi::V1::ProjectItemSerializer.new(@project_item).as_json
  end

  def update
    # TODO: add user_secrets update option
    attributes = permitted_attributes(@project_item)

    transformed = Hash.new
    transformed[:status] = attributes[:status][:value] if attributes[:status].present?
    transformed[:status_type] = attributes[:status][:type] if attributes[:status].present?

    if @project_item.update(transformed)
      render json: OrderingApi::V1::ProjectItemSerializer.new(@project_item).as_json
    else
      render json: { error: @project_item.errors.messages }, status: 400
    end
  end

  private
    def load_project_items
      @project_items = policy_scope(@project.project_items).where("iid > ?", @from_id).order(:iid).limit(@limit)
    end

    def find_and_authorize
      @project_item = @project.project_items.find_by!(iid: params[:id])
      authorize @project_item
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Project item not found" }, status: 404
    end

    def find_project
      @project = @oms.associated_projects.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Project not found" }, status: 404
    end

    def validate_payload
      schema_file = "project_item_update.json"
      JSON::Validator.validate!(
        Rails.root.join("swagger", "v1", "ordering", "project", "project_item", schema_file).to_s,
        params["project_item"].as_json
      )
    rescue JSON::Schema::ValidationError => e
      render json: { error: e.message }, status: 400
    end
end
