# frozen_string_literal: true

class Offer::Create
  def initialize(offer)
    @offer = offer
  end

  def call
    @offer.save
    if @offer.service.offers.published.size == 1
      @offer.update(order_type: @offer.service.order_type)
    end
    @offer.service.reindex
    @offer
  end
end
