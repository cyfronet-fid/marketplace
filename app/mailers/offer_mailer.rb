# frozen_string_literal: true

class OfferMailer < ApplicationMailer
  def offer_bundled(bundle, bundled_offer, recipients)
    @main_offer = bundle.main_offer
    @bundled_offer = bundled_offer
    @bundle_name = bundle.name

    mail(to: recipients, subject: "Your offer was bundled", template_name: "offer_bundled")
  end

  def offer_unbundled(bundle, unbundled_offer_full_name, recipients)
    @main_offer = bundle.main_offer
    @unbundled_offer = unbundled_offer_full_name

    mail(
      to: recipients,
      subject: "An offer bundled to your bundle offer has been unbundled",
      template_name: "offer_unbundled"
    )
  end
end
