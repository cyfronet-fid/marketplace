# frozen_string_literal: true

class Offer::Unpublish < Offer::ApplicationService
  def call
    result = @offer.update(status: :unpublished)
    unbundle!
    result
  end
end
