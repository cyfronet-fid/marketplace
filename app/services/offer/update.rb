# frozen_string_literal: true

class Offer::Update < ApplicationService
  def initialize(offer, params, bundle = nil)
    super()
    @offer = offer
    @params = params
    @bundle = bundle || @offer.main_bundles.first
  end

  def call
    effective_params = @offer.service.offers.published.size == 1 ? @params : @params.merge(default: false)

    if effective_params["primary_oms_id"] && OMS.find(effective_params["primary_oms_id"])&.custom_params.blank?
      effective_params["oms_params"] = {}
    end
    @offer.reset_added_bundled_offers!
    if @offer.update(effective_params)
      offer_bundlable? ? notify_added_bundled_offers! : unbundle_and_notify!
    end
    @offer.service.reindex
    @offer.valid?
  end

  private

  def notify_added_bundled_offers!
    @offer.added_bundled_offers&.each do |added_bundled_offer|
      Offer::Mailer::Bundled.call(@bundle, added_bundled_offer)
    end
  end

  def offer_bundlable?
    @offer.published? && @offer.internal? && @offer.service.public?
  end

  def unbundle_and_notify!
    if @bundle.present?
      @bundle.offers.each do |bundled_offer|
        Offer::Update.call(
          bundled_offer,
          { bundle_connected_offers: bundled_offer.bundle_connected_offers.to_a.reject { |o| o == @bundle.main_offer } }
        )
        Offer::Mailer::Unbundled.call(@bundle, bundled_offer)
      end
    end
  end
end
