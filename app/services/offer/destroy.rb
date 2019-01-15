# frozen_string_literal: true

class Offer::Destroy
  def initialize(offer)
    @offer = offer
  end

  def call
    @offer.destroy
  end
end
