# frozen_string_literal: true

class Offer::Update
  def initialize(offer, params)
    @offer = offer
    @params = params
  end

  def call
    if @offer.service.offers.published.size == 1
      @offer.update(@params)
    else
      @offer.update(@params.merge(default: false))
    end
    @offer.service.reindex
    @offer.valid?
  end
end
