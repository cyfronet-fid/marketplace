# frozen_string_literal: true

class Api::V1::Ess::DeployableServicesController < Api::V1::Ess::ApplicationController
  def index
    render json: cached_deployable_services
  end

  def show
    render json: Ess::DeployableServiceSerializer.new(@deployable_service).as_json, cached: true
  end
end
