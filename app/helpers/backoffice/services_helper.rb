# frozen_string_literal: true

module Backoffice::ServicesHelper
  def service_status(service)
    status_badge_class = service.published? ? "badge-success" : "badge-warning"
    content_tag(:span, service.status, class: "badge #{status_badge_class}")
  end
end
