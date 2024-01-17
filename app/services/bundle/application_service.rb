# frozen_string_literal: true

class Bundle::ApplicationService < ApplicationService
  def initialize(bundle)
    super()
    @bundle = bundle
  end

  private

  def notify_bundled!
    @bundle.offers&.each { |bundle_offer| Offer::Mailer::Bundled.call(bundle_offer, @bundle.main_offer) }
  end

  def notify_unbundled!
    @bundle.offers&.each { |bundle_offer| Offer::Mailer::Unbundled.call(bundle_offer, @bundle.main_offer) }
  end
end
