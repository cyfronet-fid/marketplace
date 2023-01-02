# frozen_string_literal: true

class Service::Publish < ApplicationService
  def initialize(service, verified: true)
    super()
    @service = service
    @status = verified ? :published : :unverified
  end

  def call
    Offer::Publish.call(@service.offers.first) if @service.offers.size == 1
    public_before = @service.public?
    notify_bundled_offers! if @service.update(status: @status) && !public_before
    Service::Mailer::SendToSubscribers.new(@service).call
  end

  private

  def notify_bundled_offers!
    @service
      .offers
      .published
      .filter(&:bundle?)
      .each do |published_bundle|
        published_bundle.bundled_connected_offers.each do |bundled_offer|
          Offer::Mailer::Bundled.call(bundled_offer, published_bundle)
        end
      end
  end
end
