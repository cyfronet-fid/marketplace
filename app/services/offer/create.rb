# frozen_string_literal: true

class Offer::Create < Offer::ApplicationService
  def call
    @offer.save
    @service.reindex
    @offer.reindex
    @offer
  end
end
