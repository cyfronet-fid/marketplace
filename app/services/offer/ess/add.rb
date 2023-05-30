# frozen_string_literal: true

class Offer::Ess::Add < ApplicationService
  def initialize(offer, async: true)
    super()
    @offer = offer
    @type = "offer"
    @async = async
  end

  def call
    @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
  end

  private

  def payload
    { action: "update", data_type: @type, data: Ess::OfferSerializer.new(@offer).as_json }.as_json
  end

  def ess_data
    {
      id: @offer.id,
      name: @offer.name,
      description: @offer.description,
      service_id: @offer.service_id,
      status: @offer.status,
      order_type: @offer.order_type,
      internal: @offer.internal,
      voucherable: @offer.voucherable,
      parameters: @offer.parameters.map(&:as_json)
    }
  end
end
