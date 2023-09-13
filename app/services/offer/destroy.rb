# frozen_string_literal: true

class Offer::Destroy < Offer::ApplicationService
  def call
    unbundle!
    result = @offer&.project_items.present? ? @offer.update(status: :deleted) : @offer.destroy

    if @service.offers.published.size == 1
      Offer::Update.call(@service.offers.published.last, { order_type: @service&.order_type })
    end
    @service.reindex
    result
  end
end
