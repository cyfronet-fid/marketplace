# frozen_string_literal: true

class Offer::Draft
  def initialize(offer)
    @offer = offer
  end

  def call
    @offer.update(status: :draft)
  end
end
