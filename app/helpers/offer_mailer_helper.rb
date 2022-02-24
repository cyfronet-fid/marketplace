# frozen_string_literal: true

module OfferMailerHelper
  def offer_full_name(offer)
    "#{offer.service.name} > #{offer.name}"
  end
end
