# frozen_string_literal: true

class Offer::Mailer::Unbundled < ApplicationService
  include OfferMailerHelper

  def initialize(bundle, unbundled_offer)
    super()
    @bundle = bundle
    @main_offer = bundle.main_offer
    @unbundled_offer = unbundled_offer
  end

  def call
    # Pass the unbundled_offer_full_name by value, so that when the offer was deleted from the DB it still works.
    OfferMailer.offer_unbundled(@bundle, @unbundled_offer, recipients).deliver_later
  end

  private

  def recipients
    @unbundled_offer.service.resource_organisation.data_administrators.map(&:email)
  end
end
