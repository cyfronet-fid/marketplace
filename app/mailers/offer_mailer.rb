# frozen_string_literal: true

class OfferMailer < ApplicationMailer
  def offer_bundled(bundled_offer, bundle_offer, recipients)
    @bundled_offer = bundled_offer
    @bundle_offer = bundle_offer

    mail(to: recipients, subject: "Your offer was bundled", template_name: "offer_bundled")
  end

  def offer_unbundled(bundle_offer, unbundled_offer_full_name, recipients)
    @bundle_offer = bundle_offer
    @unbundled_offer_full_name = unbundled_offer_full_name

    mail(
      to: recipients,
      subject: "An offer bundled to your bundle offer has been unbundled",
      template_name: "offer_unbundled"
    )
  end
end
