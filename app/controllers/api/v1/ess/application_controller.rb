# frozen_string_literal: true

class Api::V1::Ess::ApplicationController < ActionController::API
  include Pundit::Authorization
  acts_as_token_authentication_handler_for User, fallback: :exception

  before_action :perform_authorization
  before_action :load_collection, only: :index
  before_action :load_object, only: :show

  rescue_from Pundit::NotAuthorizedError do
    render json: not_authorized, status: 403
  end

  COLLECTIONS = %w[providers services datasources offers bundles catalogues].freeze

  def policy_scope(scope = controller_class, policy_scope_class: nil)
    if scope == Datasource
      super
    else
      super([:api, :v1, :ess, scope])
    end
  end

  def authorize(record = controller_class, query = nil, policy_class: nil)
    super([:api, :v1, :ess, record], query, policy_class: policy_class)
  end

  def permitted_attributes(record = controller_class, action = action_name)
    super([:api, :v1, :ess, record], action)
  end

  def perform_authorization
    if controller_class == Datasource
      authorize Datasource, policy_class: Api::V1::Ess::DatasourcePolicy
    else
      authorize controller_class
    end
  end

  def load_collection
    instance_variable_set("@#{controller_name}", policy_scope).order(:id)
  end

  def load_object
    object =
      policy_scope.respond_to?(:friendly) ? policy_scope.friendly.find(params[:id]) : policy_scope.find(params[:id])
    instance_variable_set("@#{controller_name.singularize}", object)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Resource not found" }, status: 404
  end

  def controller_class(predefined = nil)
    @klass ||= (predefined || controller_name).classify.constantize
    @klass
  end

  def not_authorized
    { error: "You are not authorized to perform this action." }
  end

  COLLECTIONS.each do |collection|
    define_method "cached_#{collection}" do
      serializer = "Ess::#{controller_class(collection)}Serializer".constantize
      Rails
        .cache
        .fetch("ess_#{collection}", expires_in: Mp::Application.config.resource_cache_ttl) do
          instance_variable_get("@#{collection}")&.map { |o| serializer.new(o).as_json }
        end
    end
  end
end
