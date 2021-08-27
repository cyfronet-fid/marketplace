# frozen_string_literal: true

class Offer::Destroy
  def initialize(offer)
    @offer = offer
  end

  def call
    @service = @offer.service
    if @offer&.project_items.present?
      @offer.update(status: :deleted)
    else
      @offer.destroy
    end
    if @service.offers.published.size == 1
      @service.offers.published.last.update(order_type: @service&.order_type)
    end
    @service.reindex
    true
  end
end
