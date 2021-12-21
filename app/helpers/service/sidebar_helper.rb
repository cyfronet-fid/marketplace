# frozen_string_literal: true

module Service::SidebarHelper
  def service_sidebar_fields
    [scientific_categorisation, categorisation, target_users, resource_availability_and_languages]
  end

  def provider_sidebar_fields
    [provider_scientific_categorisation, multimedia, address, provider_contacts]
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
      fields: ["categories"],
      type: "tree",
      nested: {
        pc_categories: "name"
      }
    }
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
      fields: ["scientific_domains"],
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
    { name: "multimedia", template: "links", fields: %w[multimedia], type: "array" }
  end

  def address
    { name: "address", template: "plain_text", fields: %w[address] }
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
