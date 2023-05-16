# frozen_string_literal: true

class Offer::Ess::Delete < ApplicationService
  def initialize(offer_id)
    super()
    @offer_id = offer_id
    @type = "offer"
  end

  def call
    # TODO: add endpoint to job
    Ess::UpdateJob.perform_later(payload)
  end

  private

  def payload
    # TODO: Must be adequate endpoint
    { action: "delete", data_type: @type, data: { id: @offer_id } }.as_json
  end
end
