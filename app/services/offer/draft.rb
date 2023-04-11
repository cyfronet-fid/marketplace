# frozen_string_literal: true

class Offer::Draft < ApplicationService
  def initialize(offer, bundle = nil)
    super()
    @offer = offer
    @bundle = bundle || @offer.main_bundles.first
  end

  def call
    result = @offer.update(status: :draft)
    unbundle_and_notify!
    result
  end

  private

  def unbundle_and_notify!
    @offer.bundle_connected_offers.each do |bundle_offer|
      Offer::Update.call(
        bundle_offer,
        { bundled_connected_offers: bundle_offer.bundled_connected_offers.to_a.reject { |o| o == @offer } }
      )
      Offer::Mailer::Unbundled.call(@bundle, @offer)
    end
  end
end
