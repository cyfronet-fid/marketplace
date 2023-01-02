# frozen_string_literal: true

class Bundle::Create < ApplicationService
  def initialize(bundle)
    super()
    @bundle = bundle
  end

  def call
    @bundle.order_type = @bundle.main_offer.order_type if @bundle.main_offer.present?
    if @bundle.save
      @bundle.main_offer.update(bundled_connected_offers: @bundle.offers)
      notify_added_bundled_offers! if @bundle.main_offer.save(validate: false)
      @bundle.service.reindex
    end
    @bundle
  end

  private

  def notify_added_bundled_offers!
    @bundle.main_offer.added_bundled_offers&.each do |added_bundled_offer|
      Offer::Mailer::Bundled.call(added_bundled_offer, @bundle.main_offer)
    end
  end
end
