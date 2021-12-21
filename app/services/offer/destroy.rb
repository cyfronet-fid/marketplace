# frozen_string_literal: true

class Offer::Destroy
  def initialize(offer)
    @offer = offer
  end

  def call
    @service = @offer.service
    @offer&.project_items.present? ? @offer.update(status: :deleted) : @offer.destroy
    @service.offers.published.last.update(order_type: @service&.order_type) if @service.offers.published.size == 1
    @service.reindex
    true
  end
end
