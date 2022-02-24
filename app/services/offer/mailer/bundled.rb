# frozen_string_literal: true

class Offer::Mailer::Bundled < ApplicationService
  def initialize(bundled_offer, bundle_offer)
    super()
    @bundled_offer = bundled_offer
    @bundle_offer = bundle_offer
  end

  def call
    OfferMailer.offer_bundled(@bundled_offer, @bundle_offer, recipients).deliver_later if should_send?
  end

  private

  def should_send?
    bundle_offer_public? && different_resource_organisation?
  end

  def bundle_offer_public?
    @bundle_offer.published? && @bundle_offer.service.public?
  end

  def different_resource_organisation?
    @bundle_offer.service.resource_organisation != @bundled_offer.service.resource_organisation
  end

  def recipients
    @bundled_offer.service.resource_organisation.data_administrators.map(&:email)
  end
end
