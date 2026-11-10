# frozen_string_literal: true

class Offer::Create < Offer::ApplicationService
  def call
    if Mp::Variant.pl?
      return @offer unless @offer.save

      @service.reload
      @service.propagate_to_ess(propagate_offers: false)
    else
      @offer.save
    end
    @service.reindex
    @offer.reindex
    @offer
  end
end
