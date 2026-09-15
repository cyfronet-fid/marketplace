# frozen_string_literal: true

class Offer::Destroy < Offer::ApplicationService
  # TEMPORARY REPOSITORY-CONSOLIDATION COMPATIBILITY:
  # marketplace still uses this operation from ordering/API removal paths,
  # whereas pl-marketplace and whitelabel-marketplace use Offer::Delete. The
  # implementations are not interchangeable. Keep this class until the three
  # variants' lifecycle behavior has been verified and deliberately reconciled.
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
