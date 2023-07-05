# frozen_string_literal: true

class Bundle::Publish < ApplicationService
  def initialize(bundle)
    super()
    @bundle = bundle
  end

  def call
    notify_bundled if @bundle.update(status: :published)
    @bundle.service.reindex
    @bundle.offers.reindex
    @bundle
  end

  private

  def notify_bundled
    @bundle.offers&.each { |bundle_offer| Offer::Mailer::Bundled.call(bundle_offer, @bundle.main_offer) }
  end
end
