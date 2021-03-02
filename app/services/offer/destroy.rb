# frozen_string_literal: true

class Offer::Destroy
  def initialize(offer)
    @offer = offer
  end

  def call
    if @offer&.project_items.present?
      @offer.update(status: :deleted)
    else
      @offer.destroy
    end
  end
end
