# frozen_string_literal: true

class Api::V1::Oms::ApiController < ActionController::API
  include Pundit
  acts_as_token_authentication_handler_for User, fallback: :exception

  rescue_from Pundit::NotAuthorizedError do
    render json: not_authorized, status: 403
  end

  def policy_scope(scope)
    super([:api, :v1, :oms, scope])
  end

  def authorize(record, query = nil)
    super([:api, :v1, :oms, record], query)
  end

  def permitted_attributes(record, action = action_name)
    super([:api, :v1, :oms, record], action)
  end

  protected
    def find_and_authorize_oms
      @oms = Oms.find(params[:oms_id])
      authorize @oms, :show?
    rescue ActiveRecord::RecordNotFound
      render json: { error: "OMS not found" }, status: 404
    end

  private
    def not_authorized
      { error: "You are not authorized to perform this action." }
    end
end
