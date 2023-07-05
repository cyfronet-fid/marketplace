# frozen_string_literal: true

class Bundle::Destroy < ApplicationService
  def initialize(bundle)
    super()
    @bundle = bundle
    @service = @bundle.service
    @bundle_offers = @bundle.offers.to_a
    @main_offer = @bundle.main_offer
  end

  def call
    result = @bundle&.project_items.present? ? @bundle.update(status: :deleted) : @bundle.destroy
    notify_unbundled! if result
    @service.reindex
    result
  end

  private

  def notify_unbundled!
    @bundle_offers.each { |bundle_offer| Offer::Mailer::Unbundled.call(bundle_offer, @main_offer) }
  end
end
