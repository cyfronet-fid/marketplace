# frozen_string_literal: true

class Bundle::Update < ApplicationService
  def initialize(bundle, params)
    super()
    @bundle = bundle
    @params = params
  end

  def call
    @bundle.main_offer.reset_added_bundled_offers!
    offer_ids = @params["offer_ids"].dup.reject(&:blank?).map(&:to_i)
    offer = Offer.find(@params["main_offer_id"])
    offer.update(bundled_connected_offers: Offer.find(offer_ids))
    @params["order_type"] = Offer.find(@params["main_offer_id"]).order_type
    notify_added_bundled_offers! if @bundle.update(@params)
    @bundle.service.reindex
    @bundle.offers.reindex
    @bundle.valid?
  end

  private

  def notify_added_bundled_offers!
    @bundle.main_offer.added_bundled_offers&.each do |added_bundled_offer|
      Offer::Mailer::Bundled.call(@bundle, added_bundled_offer)
    end
  end
end
