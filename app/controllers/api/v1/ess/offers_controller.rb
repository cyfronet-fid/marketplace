# frozen_string_literal: true

class Api::V1::Ess::OffersController < Api::V1::Ess::ApplicationController
  def index
    render json: cached_offers
  end

  def show
    render json: Ess::OfferSerializer.new(@offer).as_json, cached: true
  end
end
