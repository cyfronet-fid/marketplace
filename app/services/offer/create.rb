# frozen_string_literal: true

class Offer::Create < ApplicationService
  def initialize(offer)
    super()
    @offer = offer
  end

  def call
    notify_added_bundled_offers! if @offer.save
    @offer.service.reindex
    @offer
  end

  private

  def notify_added_bundled_offers!
    @offer.added_bundled_offers&.each { |added_bundled_offer| Offer::Mailer::Bundled.call(added_bundled_offer, @offer) }
  end
end
