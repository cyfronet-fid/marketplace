# frozen_string_literal: true

class Api::V1::Oms::ApiController < ActionController::API
  include Pundit
  before_action :oms_authorization!

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

  private
    def not_authorized
      {
        error: "You are not authorized to perform this action."
      }
    end

    def oms_authorization!
      authorize :oms, :show?
    end
end
