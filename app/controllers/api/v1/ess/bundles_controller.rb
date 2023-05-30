# frozen_string_literal: true

class Api::V1::Ess::BundlesController < Api::V1::Ess::ApplicationController
  def index
    render json: cached_bundles
  end

  def show
    render json: Ess::BundleSerializer.new(@bundle).as_json, cached: true
  end
end
