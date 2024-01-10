# frozen_string_literal: true

class Api::V1::Ess::CataloguesController < Api::V1::Ess::ApplicationController
  def index
    render json: cached_catalogues
  end

  def show
    render json: Ess::CatalogueSerializer.new(@catalogue).as_json, cached: true
  end
end
