# frozen_string_literal: true

class Offer::Destroy < ApplicationService
  def initialize(offer)
    super()
    @offer = offer
  end

  def call
    @service = @offer.service
    @bundles = @offer.bundles.to_a
    unbundle!
    result = @offer&.project_items.present? ? @offer.update(status: :deleted) : @offer.destroy

    if @service.offers.published.size == 1
      Offer::Update.call(@service.offers.published.last, { order_type: @service&.order_type })
    end
    @service.reindex
    result
  end

  private

  def unbundle!
    @bundles.each do |bundle|
      Bundle::Update.call(
        bundle,
        { offer_ids: bundle.offers.to_a.reject { |o| o == @offer }.map(&:id) },
        external_update: true
      )
    end
  end
end
