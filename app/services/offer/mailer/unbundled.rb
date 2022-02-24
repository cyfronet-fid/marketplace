# frozen_string_literal: true

class Offer::Mailer::Unbundled < ApplicationService
  include OfferMailerHelper

  def initialize(bundle_offer, unbundled_offer)
    super()
    @bundle_offer = bundle_offer
    @unbundled_offer = unbundled_offer
  end

  def call
    # Pass the unbundled_offer_full_name by value, so that when the offer was deleted from the DB it still works.
    OfferMailer.offer_unbundled(@bundle_offer, unbundled_offer_full_name, recipients).deliver_later
  end

  private

  def unbundled_offer_full_name
    offer_full_name(@unbundled_offer)
  end

  def recipients
    @bundle_offer.service.resource_organisation.data_administrators.map(&:email)
  end
end
