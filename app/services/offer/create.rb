# frozen_string_literal: true

class Offer::Create < ApplicationService
  def initialize(offer)
    super()
    @offer = offer
  end

  def call
    @offer.save
    @offer.service.reindex
    @offer.reindex
    @offer
  end
end
