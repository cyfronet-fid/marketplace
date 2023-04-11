# frozen_string_literal: true

class Service::Draft < ApplicationService
  def initialize(service)
    super()
    @service = service
  end

  def call
    public_before = @service.public?
    result = @service.update(status: :draft)
    unbundle_and_notify! if result && public_before
    result
  end

  private

  def unbundle_and_notify!
    @service.bundles.each do |bundle|
      bundle.offers.each do |bundle_offer|
        Offer::Update.call(
          bundle_offer,
          { bundle_connected_offers: bundle_offer.bundle_connected_offers.to_a.reject { |o| o == bundle.main_offer } }
        )
        Offer::Mailer::Unbundled.call(bundle, bundle_offer)
      end
    end
  end
end
