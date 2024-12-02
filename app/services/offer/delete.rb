# frozen_string_literal: true

class Offer::Delete < Offer::ApplicationService
  def call
    unbundle!
    @offer.status = :deleted
    result =
      if @offer.project_items&.size&.positive? || @offer.main_bundles&.size&.positive?
        @offer.save!(validate: false)
      else
        @offer.destroy!
      end

    if !@service.deleted? && @service.offers.published.size == 1
      Offer::Update.call(@service.offers.published.last, { order_type: @service&.order_type })
    end
    @service.reindex
    result
  end
end
