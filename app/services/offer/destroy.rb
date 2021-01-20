# frozen_string_literal: true

class Offer::Destroy
  def initialize(offer)
    @offer = offer
  end

  def call
    if @offer&.project_items.present?
      Offer::Draft.new(@offer).call
    else
      @offer.destroy
    end
  end
end
