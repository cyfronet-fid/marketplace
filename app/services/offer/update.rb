# frozen_string_literal: true

class Offer::Update
  def initialize(offer, params)
    @offer = offer
    @params = params
  end

  def call
    @offer.service.offers.published.size == 1 ? @offer.update(@params) : @offer.update(@params.merge(default: false))
    @offer.service.reindex
    @offer.valid?
  end
end
