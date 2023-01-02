# frozen_string_literal: true

class Bundle::Destroy < ApplicationService
  def initialize(bundle)
    super()
    @bundle = bundle
  end

  def call
    @service = @bundle.service
    @bundle_offers = @bundle.main_offer.bundle_connected_offers.to_a
    if @bundle&.project_items.present?
      if @bundle.update(status: :deleted)
        unbundle!
        notify_unbundled!
      end
    elsif @bundle.destroy
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
