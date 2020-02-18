# frozen_string_literal: true

module Backoffice::ServicesHelper
  BADGES = {
    "published" => "badge-success",
    "unverified" => "badge-warning",
    "draft" => "badge-error"
  }

  def service_status(service)
    content_tag(:span, service.status, class: "badge #{BADGES[service.status]}")
  end

  def offers_status(service)
    if service.offers.blank?
      content_tag(:span, "NO OFFERS", class: "badge badge-error")
    elsif service.published? && service.offers.published.blank?
      content_tag(:span, "NO PUBLISHED OFFERS", class: "badge badge-warning")
    end
  end

  def offer_status(offer)
    content_tag(:span, offer.status, class: "badge #{BADGES[offer.status]}")
  end
end
