# frozen_string_literal: true

class Offer::Mailer::Bundled < ApplicationService
  def initialize(bundle, bundled_offer)
    super()
    @bundle = bundle
    @bundled_offer = bundled_offer
  end

  def call
    OfferMailer.offer_bundled(@bundle, @bundled_offer, recipients).deliver_later if should_send?
  end

  private

  def should_send?
    bundled_offer_public? && different_resource_organisation?
  end

  def bundled_offer_public?
    @bundled_offer.published? && @bundled_offer.service.public?
  end

  def different_resource_organisation?
    @bundled_offer.service.resource_organisation != @bundle.main_offer.service.resource_organisation
  end

  def recipients
    @bundled_offer.service.resource_organisation.data_administrators.map(&:email)
  end
end
