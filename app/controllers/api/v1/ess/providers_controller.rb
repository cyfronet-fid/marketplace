# frozen_string_literal: true

class Api::V1::Ess::ProvidersController < Api::V1::Ess::ApplicationController
  def index
    render json: cached_providers
  end

  def show
    render json: Ess::ProviderSerializer.new(@provider).as_json, cached: true
  end
end
