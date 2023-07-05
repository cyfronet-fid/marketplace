# frozen_string_literal: true

class Bundle::Draft < ApplicationService
  def initialize(bundle, empty_offers: false)
    super()
    @bundle = bundle
    @empty_offers = empty_offers
  end

  def call
    if @empty_offers
      @bundle.status = "draft"
      @bundle.offers = []
      @bundle.save!(validate: false)
    else
      @bundle.update(status: :draft)
      notify_unbundled!
    end
    @bundle
  end

  private

  def notify_unbundled!
    @bundle.offers&.each { |bundle_offer| Offer::Mailer::Unbundled.call(bundle_offer, @bundle.main_offer) }
  end
end
