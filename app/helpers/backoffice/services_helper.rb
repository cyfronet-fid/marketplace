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

  def offer_status(offer)
    content_tag(:span, offer.status, class: "badge #{BADGES[offer.status]}")
  end
end
