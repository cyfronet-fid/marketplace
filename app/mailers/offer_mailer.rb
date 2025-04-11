# frozen_string_literal: true

class OfferMailer < ApplicationMailer
  def notify_watcher(offer, user)
    @offer = offer
    @user = user
    mail(to: @user.email, subject: "#{@offer.name} is now available", template_name: "offer_available")
  end

  def notify_provider(offer, provider)
    @offer = offer
    @provider = provider
    mail(
      to: @provider.email,
      subject: "#{@offer.name} has Expired – Manage Your Resource",
      template_name: "offer_expired"
    )
  end

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
