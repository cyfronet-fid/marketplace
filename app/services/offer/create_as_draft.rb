# frozen_string_literal: true

class Offer::CreateAsDraft < Offer::ApplicationService
  def call
    @offer.save(validate: false)
    @service.reindex
    @offer.reindex
    @offer
  end
end
