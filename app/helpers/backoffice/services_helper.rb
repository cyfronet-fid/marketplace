# frozen_string_literal: true

module Backoffice::ServicesHelper
  BADGES = {
    "published" => "badge-success",
    "draft" => "badge-draft",
    "errored" => "badge-warning",
    "deleted" => "badge-error"
  }.freeze

  def service_status(service, additional_classes = nil)
    content_tag(:span, service.status, class: "badge #{BADGES[service.status]} #{additional_classes}")
  end

  def offers_status(service)
    if service.offers.blank?
      content_tag(:span, "NO OFFERS", class: "badge badge-error")
    elsif service.published? && service.offers.published.blank?
      content_tag(:span, "NO PUBLISHED OFFERS", class: "badge badge-warning")
    end
  end

  def collapsed?(service, fields)
    (service.errors.attribute_names & fields).blank?
  end

  def offer_missing?(param, param_options)
    param_options["mandatory"] && @offer.errors[:oms_params].present? && @offer.oms_params[param].blank?
  end
end
