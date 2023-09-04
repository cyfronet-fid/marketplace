# frozen_string_literal: true

class Bundle::Publish < ApplicationService
  def initialize(bundle)
    super()
    @bundle = bundle
  end

  def call
    if @bundle.update(status: :published)
      notify_bundled
      @bundle.service.reindex
      @bundle.offers.reindex
    else
      return false
    end
    @bundle
  end

  private

  def notify_bundled
    @bundle.offers&.each { |bundle_offer| Offer::Mailer::Bundled.call(bundle_offer, @bundle.main_offer) }
  end
end
