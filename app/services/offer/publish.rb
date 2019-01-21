# frozen_string_literal: true

class Offer::Publish
  def initialize(offer)
    @offer = offer
  end

  def call
    @offer.update(status: :published)
  end
end
