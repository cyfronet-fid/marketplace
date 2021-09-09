# frozen_string_literal: true

class Offer::Create
  def initialize(offer)
    @offer = offer
  end

  def call
    @offer.save
    @offer.service.reindex
    @offer
  end
end
