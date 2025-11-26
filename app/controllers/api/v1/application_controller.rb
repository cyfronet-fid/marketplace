# frozen_string_literal: true

class Api::V1::ApplicationController < ActionController::API
  include Pundit::Authorization
  # OAuth2 Bearer first, then fallback to SimpleTokenAuthentication header
  before_action :authenticate_with_bearer_token
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

  # Try OAuth2 Bearer authentication using OIDC (same issuer as OmniAuth)
  # If Authorization header is missing — do nothing and let SimpleTokenAuthentication handle it.
  # If Authorization header is present but invalid — return 401.
  def authenticate_with_bearer_token
    auth = request.authorization
    return unless auth&.start_with?("Bearer ")

    token = auth.split(" ", 2)[1]
    begin
      verifier = Oidc::TokenVerifier.instance
      claims = verifier.verify!(token)

      # Prefer matching by `sub` (stable subject) which we store in `uid`.
      user = User.find_by(uid: claims["sub"]) || (claims["email"].present? ? User.find_by(email: claims["email"]) : nil)

      if user
        # Ensure Devise knows about the user in this request
        sign_in(user, store: false)
      else
        render json: { error: "User not found for provided OAuth token" }, status: :unauthorized and return
      end
    rescue Oidc::TokenVerifier::VerificationError => e
      render json: { error: "Invalid OAuth token", details: e.message }, status: :unauthorized and return
    rescue StandardError => e
      Rails.logger.error("Bearer auth error: #{e.class}: #{e.message}")
      render json: { error: "OAuth token verification failed" }, status: :unauthorized and return
    end
  end
end
