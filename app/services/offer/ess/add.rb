# frozen_string_literal: true

class Offer::Ess::Add < ApplicationService
  def initialize(offer, async: true, dry_run: false)
    super()
    @offer = offer
    @type = "offer"
    @async = async
    @dry_run = dry_run
  end

  def call
    if @dry_run
      ess_data
    else
      @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
    end
  end

  private

  def payload
    { action: "update", data_type: @type, data: ess_data }.as_json
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
