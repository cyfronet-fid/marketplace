# frozen_string_literal: true

class Api::V1::ApplicationController < ActionController::API
  include Pundit::Authorization
  acts_as_token_authentication_handler_for User, fallback: :exception

  rescue_from Pundit::NotAuthorizedError do
    render json: not_authorized, status: 403
  end

  def policy_scope(scope)
    super([:api, :v1, scope])
  end

  def authorize(record, query = nil)
    super([:api, :v1, record], query)
  end

  def permitted_attributes(record, action = action_name)
    super([:api, :v1, record], action)
  end

  protected

  def find_and_authorize_oms
    @oms = OMS.find(params[:oms_id])
    authorize @oms, :show?
  rescue ActiveRecord::RecordNotFound
    render json: { error: "OMS not found" }, status: 404
  end

  def validate_from_id
    @from_id = params[:from_id].present? ? params[:from_id].to_i : 0
    render json: { error: "'from_id' must be a non-negative integer" }, status: 400 if @from_id.negative?
  end

  def validate_limit
    @limit = params[:limit].present? ? params[:limit].to_i : 20
    render json: { error: "'limit' must be a positive integer" }, status: 400 if @limit <= 0
  end

  private

  def not_authorized
    { error: "You are not authorized to perform this action." }
  end
end
