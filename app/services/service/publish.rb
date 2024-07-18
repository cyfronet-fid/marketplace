# frozen_string_literal: true

class Service::Publish < Service::ApplicationService
  def call
    public_before = @service.public?
    if @service.update(status: :published)
      Offer::Publish.call(@service.offers.first) if @service.offers.size == 1
      notify_bundled_offers! unless public_before
      Service::Mailer::SendToSubscribers.new(@service).call
    else
      false
    end
  end

  private

  def notify_bundled_offers!
    @service.bundles.published.each do |published_bundle|
      published_bundle.offers.each do |bundled_offer|
        Offer::Mailer::Bundled.call(bundled_offer, published_bundle.main_offer)
      end
    end
  end
end
