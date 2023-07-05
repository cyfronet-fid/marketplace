# frozen_string_literal: true

class Bundle::Create < ApplicationService
  def initialize(bundle)
    super()
    @bundle = bundle
  end

  def call
    @bundle.order_type = @bundle.main_offer.order_type if @bundle.main_offer.present?
    if @bundle.save
      notify_added_bundled_offers!
      @bundle.service.reindex
    end
    @bundle
  end

  private

  def notify_added_bundled_offers!
    @bundle&.offers&.each { |added_bundled_offer| Offer::Mailer::Bundled.call(added_bundled_offer, @bundle.main_offer) }
  end
end
