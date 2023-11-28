# frozen_string_literal: true

module Presentable::LinksHelper
  def service_fields
    [links]
  end

  def provider_fields
    [provider_links, status]
  end

  def datasource_fields
    [datasource_links]
  end

  private

  def links
    {
      name: "links",
      template: "links",
      fields: %w[webpage_url helpdesk_url helpdesk_email manual_url training_information_url]
    }
  end

  def provider_links
    { name: "links", template: "links", fields: %w[website] }
  end

  def datasource_links
    {
      name: "links",
      template: "links",
      fields: %w[webpage_url helpdesk_url helpdesk_email manual_url training_information_url]
    }
  end

  def status
    {
      name: "statuses",
      template: "list",
      fields: %w[legal_statuses provider_life_cycle_statuses],
      nested: {
        legal_statuses: "name",
        provider_life_cycle_statuses: "name"
      }
    }
  end
end
