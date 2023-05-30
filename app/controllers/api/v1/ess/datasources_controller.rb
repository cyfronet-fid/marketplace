# frozen_string_literal: true

class Api::V1::Ess::DatasourcesController < Api::V1::Ess::ApplicationController
  def index
    render json: cached_datasources
  end

  def show
    render json: Ess::DatasourceSerializer.new(@datasource).as_json, cached: true
  end

  def policy_scope
    super(Datasource, policy_scope_class: Api::V1::Ess::DatasourcePolicy::Scope)
  end
end
