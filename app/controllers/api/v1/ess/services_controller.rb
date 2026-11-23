# frozen_string_literal: true

class Api::V1::Ess::ServicesController < Api::V1::Ess::ApplicationController
  def index
    render json: cached_services
  end

  def show
    render json: Ess::ServiceSerializer.new(@service).as_json, cached: true
  end
end
