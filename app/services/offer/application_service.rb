# frozen_string_literal: true

class Offer::ApplicationService < ApplicationService
  def initialize(offer)
    super()
    @offer = offer
    @service = @offer.service
    @bundles = @offer.bundles.to_a
  end

  private

  def unbundle!
    @bundles.each do |bundle|
      Bundle::Update.call(
        bundle,
        { offer_ids: bundle.offer_ids.to_a.reject { |o| o == @offer.id } }.stringify_keys,
        external_update: true
      )
    end
  end
end
