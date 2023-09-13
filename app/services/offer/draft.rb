# frozen_string_literal: true

class Offer::Draft < Offer::ApplicationService
  def call
    result = @offer.update(status: :draft)
    unbundle!
    result
  end
end
