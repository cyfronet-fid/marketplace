# frozen_string_literal: true

class Offer::Update < ApplicationService
  def initialize(offer, params)
    super()
    @offer = offer
    @params = params
  end

  def call
    effective_params = @offer.service.offers.published.size == 1 ? @params : @params.merge(default: false)
    @offer.reset_added_bundled_offers!
    if @offer.update(effective_params)
      offer_bundlable? ? notify_added_bundled_offers! : unbundle_and_notify!
    end
    @offer.service.reindex
    @offer.valid?
  end

  private

  def notify_added_bundled_offers!
    @offer.added_bundled_offers&.each { |added_bundled_offer| Offer::Mailer::Bundled.call(added_bundled_offer, @offer) }
  end

  def offer_bundlable?
    @offer.published? && @offer.internal? && @offer.service.public?
  end

  def unbundle_and_notify!
    @offer.bundle_offers.each do |bundle_offer|
      Offer::Update.call(bundle_offer, { bundled_offers: bundle_offer.bundled_offers.to_a.reject { |o| o == @offer } })
      Offer::Mailer::Unbundled.call(bundle_offer, @offer)
    end
  end
end
