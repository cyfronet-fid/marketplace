# frozen_string_literal: true

class Offer::Destroy < ApplicationService
  def initialize(offer)
    super()
    @offer = offer
  end

  def call
    @service = @offer.service
    @bundle_offers = @offer.bundle_connected_offers.to_a
    if @offer&.project_items.present?
      if @offer.update(status: :deleted)
        unbundle!
        notify_unbundled!
      end
    elsif @offer.destroy
      notify_unbundled!
    end
    if @service.offers.published.size == 1
      Offer::Update.call(@service.offers.published.last, { order_type: @service&.order_type })
    end
    @service.reindex
    true
  end

  private

  def unbundle!
    @bundle_offers.each do |bundle_offer|
      Offer::Update.call(
        bundle_offer,
        { bundled_connected_offers: bundle_offer.bundled_connected_offers.to_a.reject { |o| o == @offer } }
      )
    end
  end

  def notify_unbundled!
    @bundle_offers.each { |bundle_offer| Offer::Mailer::Unbundled.call(bundle_offer, @offer) }
  end
end
