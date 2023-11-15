# frozen_string_literal: true

module Presentable::SidebarHelper
  def service_sidebar_fields
    [
      pid,
      scientific_categorisation,
      categorisation,
      monitoring_data,
      analytics,
      target_users,
      resource_availability_and_languages
    ]
  end

  def provider_sidebar_fields
    [pid("Provider"), provider_scientific_categorisation, multimedia, address, provider_contacts]
  end

  def datasource_sidebar_fields
    [pid, scientific_categorisation, categorisation, target_users, resource_availability_and_languages]
  end

  private

  def scientific_categorisation
    {
      name: "scientific_categorisation",
      template: "classification",
      fields: ["scientific_domains"],
      nested: {
        scientific_domains: "name"
      }
    }
  end

  def categorisation
    {
      name: "categorisation",
      template: "array",
      fields: %w[categories service_categories],
      type: "tree",
      nested: {
        categories: "name",
        service_categories: "name"
      }
    }
  end

  def monitoring_data
    { name: "uptime_monitoring", fields: %w[availability_cache reliability_cache], template: "monitoring" }
  end

  def analytics
    { name: "Statistics", fields: %w[analytics], template: "analytics" }
  end

  def target_users
    { name: "target_users", template: "array", fields: ["target_users"], nested: { target_users: "name" } }
  end

  def resource_availability_and_languages
    { name: "resource_availability_and_languages", template: "map", fields: %w[languages geographical_availabilities] }
  end

  def provider_scientific_categorisation
    {
      name: "classification",
      template: "classification",
      fields: %w[scientific_domains],
      nested: {
        scientific_domains: "name"
      }
    }
  end

  def provider_categorisation
    {
      name: "provider_categorisation",
      template: "array",
      fields: ["pc_categories"],
      type: "tree",
      nested: {
        pc_categories: "name"
      }
    }
  end

  def multimedia
    { name: "multimedia", template: "links", fields: %w[link_multimedia_urls], type: "array" }
  end

  def address
    { name: "address", template: "plain_text", fields: %w[address] }
  end

  def pid(type = "Service")
    { name: "#{type} Identifiers", template: "object", clazz: "alternative_identifiers", fields: %w[value] }
  end

  def provider_contacts
    {
      name: "contact",
      template: "object",
      fields: %w[full_name email phone position],
      type: "array",
      clazz: "public_contacts",
      nested: {
        email: "email"
      }
    }
  end
end
