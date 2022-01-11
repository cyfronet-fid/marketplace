# frozen_string_literal: true

module Backoffice::ServicesHelper
  BADGES = {
    "published" => "badge-success",
    "unverified" => "badge-warning",
    "draft" => "badge-draft",
    "errored" => "badge-error",
    "deleted" => "badge-error"
  }.freeze

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

  def collapsed?(service, fields)
    (service.errors.attribute_names & fields).blank?
  end

  def offer_missing?(param, param_options)
    param_options["mandatory"] && @offer.errors[:oms_params].present? && @offer.oms_params[param].blank?
  end

  def preview_link_parameters(is_preview)
    if is_preview
      { disabled: true, tabindex: -1, class: "disabled", "data-tooltip": "Element disabled in the preview mode" }
    else
      {}
    end
  end
end
