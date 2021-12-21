# frozen_string_literal: true

class Api::V1::OMSes::Projects::ProjectItemsController < Api::V1::ApplicationController
  before_action :find_and_authorize_oms
  before_action :prepare_params, only: :update
  before_action :find_project
  before_action :validate_from_id, only: :index
  before_action :validate_limit, only: :index
  before_action :load_project_items, only: :index
  before_action :find_and_authorize, only: %i[show update]
  before_action :validate_payload, only: :update

  def index
    render json: { project_items: @project_items.map { |pi| serialize_with_obfuscation(pi) } }
  end

  def show
    render json: serialize_with_obfuscation(@project_item)
  end

  def update
    attributes = permitted_attributes(@project_item)

    if @project_item.update(transform(attributes))
      excluded_secret_keys = attributes[:user_secrets].present? ? attributes[:user_secrets].keys : []
      render json: serialize_with_obfuscation(@project_item, excluded_secret_keys)
    else
      render json: { error: @project_item.errors.to_hash }, status: 400
    end
  end

  private

  def find_project
    @project = @oms.projects.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: 404
  end

  def find_and_authorize
    @project_item = @oms.project_items_for(@project).find_by!(iid: params[:id])
    authorize @project_item
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project item not found" }, status: 404
  end

  def load_project_items
    @project_items =
      policy_scope(@oms.project_items_for(@project))
        .where("project_items.iid > ?", @from_id)
        .order("project_items.iid")
        .limit(@limit)
  end

  def prepare_params
    params[:project_item][:status] = params[:status] if params[:status].present?
    params[:project_item][:user_secrets] = params[:user_secrets] if params[:user_secrets].present?
  end

  def validate_payload
    schema_file = "project_item_update.json"
    JSON::Validator.validate!(
      Rails.root.join("swagger", "v1", "project_item", schema_file).to_s,
      params[:project_item].as_json
    )
  rescue JSON::Schema::ValidationError => e
    render json: { error: e.message }, status: 400
  end

  def transform(attributes)
    transformed = {}
    if attributes[:status].present?
      transformed[:status] = attributes[:status][:value]
      transformed[:status_type] = attributes[:status][:type]
    end
    if attributes[:user_secrets].present?
      transformed[:user_secrets] = @project_item.user_secrets.merge(attributes[:user_secrets])
    end
    transformed
  end

  def serialize_with_obfuscation(project_item, excluded = [])
    Api::V1::ProjectItemSerializer.new(project_item, non_obfuscated_user_secrets: excluded).as_json
  end
end
