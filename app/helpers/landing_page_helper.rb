# frozen_string_literal: true

module LandingPageHelper
  SEARCH_ITEMS = {
    software: "Software",
    service: "Services",
    publication: "Publications",
    dataset: "Data",
    "data-source": "Data Sources",
    training: "Training Materials"
  }.freeze

  def external_search_base_url
    Rails.configuration.search_service_base_url
  end
end
