# frozen_string_literal: true

class Api::V1::ApiController < ActionController::API
  include Pundit
  acts_as_token_authentication_handler_for User, fallback: :exception
  before_action :offering_api_authorization!

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

  private
    def not_authorized
      {
        error: "You are not authorized to perform this action."
      }
    end

    def offering_api_authorization!
      authorize :api, :show?
    end
end
