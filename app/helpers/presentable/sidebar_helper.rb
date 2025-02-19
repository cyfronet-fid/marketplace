# frozen_string_literal: true

module Presentable::SidebarHelper
  def service_sidebar_fields
    [monitoring_data, target_users, tags, availability]
  end

  def provider_sidebar_fields
    [pid("Provider"), provider_managers, main_contact, provider_contacts]
  end

  private

  def address
    { name: "address", template: "plain_text", fields: %w[address] }
  end

  def availability
    {
      name: "availability_and_language",
      template: "map",
      fields: %w[geographical_availabilities languages],
      with_desc: true,
      active_when_suspended: false
    }
  end

  def monitoring_data
    {
      name: "uptime_monitoring",
      fields: %w[availability_cache reliability_cache],
      template: "monitoring",
      active_when_suspended: false
    }
  end

  def multimedia
    { name: "multimedia", template: "links", fields: %w[link_multimedia_urls], type: "array" }
  end

  def pid(type = "Service")
    { name: "#{type} Identifiers", template: "object", clazz: "alternative_identifiers", fields: %w[value] }
  end

  def main_contact
    {
      name: "main_contact",
      template: "object",
      fields: %w[first_name last_name email],
      type: "object",
      clazz: "main_contact",
      nested: {
        email: "email"
      }
    }
  end

  def provider_contacts
    {
      name: "contact",
      template: "object",
      fields: %w[first_name last_name email],
      type: "array",
      clazz: "public_contacts",
      nested: {
        email: "email"
      }
    }
  end

  def provider_managers
    {
      name: "provider_managers",
      template: "object",
      fields: %w[first_name last_name email],
      type: "array",
      clazz: "public_contacts",
      nested: {
        email: "email"
      }
    }
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

  def tags
    {
      name: "tags",
      template: "filter",
      fields: %w[sliced_tag_list],
      with_desc: false,
      filter_query: {
        sliced_tag_list: "tag_list"
      }
    }
  end

  def target_users
    {
      name: "target_users",
      template: "filter",
      fields: %w[target_users],
      with_desc: false,
      nested: {
        target_users: "name"
      },
      filter_query: {
        target_users: "dedicated_for"
      }
    }
  end
end
