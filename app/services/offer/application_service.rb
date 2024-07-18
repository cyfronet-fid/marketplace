# frozen_string_literal: true

class Offer::ApplicationService < ApplicationService
  def initialize(offer)
    super()
    @offer = offer
    @service = @offer.service
    @bundles = @offer.bundles.to_a
    @main_bundles = @offer.main_bundles.to_a
  end

  private

  def unbundle!
    @main_bundles.each { |bundle| Bundle::Unpublish.call(bundle) }
    @bundles.each do |bundle|
      Bundle::Update.call(
        bundle,
        { offer_ids: bundle.offer_ids.to_a.reject { |o| o == @offer.id } }.stringify_keys,
        external_update: true
      )
    end
  end

  def disconnect_main_offer!
    @main_bundles.each do |bundle|
      bundle.main_offer = nil
      bundle.save!(validate: false)
    end
  end
end
