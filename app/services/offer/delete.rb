# frozen_string_literal: true

class Offer::Delete < Offer::ApplicationService
  # TEMPORARY REPOSITORY-CONSOLIDATION COMPATIBILITY:
  # pl-marketplace and whitelabel-marketplace use this operation at every
  # offer-removal entry point, while marketplace still has call sites using
  # Offer::Destroy. The implementations have observably different handling of
  # main bundles, persistence failures, and deleted services. Keep both until
  # those flows are verified for all three variants; do not unify them as a
  # cleanup during the initial consolidation.
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
