# frozen_string_literal: true

class Offer::Draft < ApplicationService
  def initialize(offer)
    super()
    @offer = offer
  end

  def call
    result = @offer.update(status: :draft)
    unbundle!
    result
  end

  private

  def unbundle!
    @offer.bundles.each do |bundle|
      Bundle::Update.call(
        bundle,
        { offers: bundle.offers.to_a.reject { |o| o.id == @offer.id } }.stringify_keys,
        external_update: true
      )
    end
    @offer.main_bundles.each { |bundle| Bundle::Draft.call(bundle) }
  end
end
