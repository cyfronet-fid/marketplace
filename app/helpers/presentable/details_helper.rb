# frozen_string_literal: true

module Presentable::DetailsHelper
  include Backoffice::ServicesHelper

  def service_details_columns
    [
      [classification, availability, marketing, dependencies, attribution, order],
      [public_contacts, maturity_information, financial_information],
      [changelog]
    ]
  end

  def guidelines_details_columns
    [[guidelines]]
  end

  def provider_details_columns
    [
      [provider_classification, esfri_types, esfri_domains, meril_scientific_domains],
      [networks, areas_of_activity, affiliations, certifications, catalogue],
      [
        resource_profile_4? ? hosting_legal_entity : hosting_legal_entity_string,
        structure_types,
        societal_grand_challenges,
        national_roadmaps
      ]
    ]
  end

  def datasource_details_columns
    [
      [classification, availability, marketing, dependencies, attribution, order],
      [public_contacts, maturity_information, management, financial_information],
      [
        version_control,
        changelog,
        datasource_policies,
        persistent_identity_systems,
        datasource_content,
        research_product_licensing,
        research_product_access_policies,
        research_product_metadata_licensing,
        research_product_metadata_access_policies
      ]
    ]
  end

  def public_contacts
    {
      name: "public_contacts",
      template: "object",
      fields: %w[full_name email phone position_in_organisation],
      type: "array",
      clazz: "public_contacts",
      nested: {
        email: "email"
      }
    }
  end

  private

  def provider_classification
    { name: "classification", template: "array", fields: %w[tag_list], with_desc: true, nested: { tag_list: "tag" } }
  end

  def classification
    {
      name: "classification",
      template: "array",
      fields: %w[marketplace_locations target_users access_types access_modes],
      with_desc: true,
      nested: {
        marketplace_locations: "name",
        target_users: "name",
        access_types: "name",
        access_modes: "name"
      }
    }
  end

  def availability
    { name: "availability", template: "array", fields: %w[geographical_availabilities languages], with_desc: true }
  end

  def marketing
    { name: "marketing", template: "links", fields: %w[link_multimedia_urls link_use_cases_urls], type: "array" }
  end

  def dependencies
    {
      name: "dependencies",
      template: "array",
      fields: dependencies_fields,
      with_desc: true,
      nested: {
        required_services: "service",
        related_services: "service",
        catalogue: "name",
        platforms: "name"
      }
    }
  end

  def dependencies_fields
    platforms = resource_profile_4? ? "platforms" : "related_platforms"
    ["required_services", "related_services", platforms, "catalogue"]
  end

  def attribution
    {
      name: "attribution",
      template: "array",
      fields: %w[funding_bodies funding_programs grant_project_names],
      with_desc: true,
      nested: {
        funding_bodies: "name",
        funding_programs: "name"
      }
    }
  end

  def order
    {
      name: "order",
      template: "array",
      fields: %w[order_type order_url],
      nested: {
        order_type: "label",
        order_url: "link"
      },
      with_desc: true
    }
  end

  def maturity_information
    {
      name: "maturity_information",
      template: "array",
      fields: %w[trls life_cycle_statuses certifications standards open_source_technologies version last_update],
      with_desc: true,
      nested: {
        trls: "name",
        life_cycle_statuses: "name"
      }
    }
  end

  def management
    {
      name: "management",
      template: "links",
      fields: %w[
        helpdesk_url
        manual_url
        terms_of_use_url
        privacy_policy_url
        access_policies_url
        training_information_url
        status_monitoring_url
        maintenance_url
      ],
      with_desc: true
    }
  end

  def datasource_policies
    { name: "policies", template: "links", fields: %w[submission_policy_url preservation_policy_url], with_desc: true }
  end

  def version_control
    { name: "version_control", template: "array", fields: %w[version_control] }
  end

  def persistent_identity_systems
    {
      name: "persistent_identity_systems",
      template: "object",
      fields: %w[entity_type entity_type_scheme_names],
      type: "array",
      with_desc: true,
      clazz: "persistent_identity_systems",
      nested: {
        entity_type: "name"
      }
    }
  end

  def datasource_content
    {
      name: "datasource_content",
      template: "array",
      fields: %w[jurisdiction datasource_classification research_entity_types thematic],
      with_desc: true
    }
  end

  def research_product_licensing
    {
      name: "research_product_licensing",
      template: "links",
      fields: %w[link_research_product_license_urls],
      type: "array"
    }
  end

  def research_product_access_policies
    {
      name: "research_product_access_policies",
      template: "list",
      fields: %w[research_product_access_policies],
      nested: {
        research_product_access_policies: "name"
      }
    }
  end

  def research_product_metadata_licensing
    {
      name: "research_product_metadata_licensing",
      template: "links",
      fields: %w[link_research_product_metadata_license_urls],
      type: "array"
    }
  end
  def research_product_metadata_access_policies
    {
      name: "research_product_metadata_access_policies",
      template: "list",
      fields: %w[research_product_metadata_access_policies],
      nested: {
        research_product_metadata_access_policies: "name"
      }
    }
  end

  def financial_information
    { name: "financial_information", template: "links", fields: %w[payment_model_url pricing_url] }
  end

  def changelog
    { name: "changelog", template: "list", fields: ["changelog"] }
  end

  def guidelines
    { name: "Supported Interoperability Guidelines", template: "links", fields: ["guidelines"], type: "guideline" }
  end

  def statuses
    {
      name: "statuses",
      template: "array",
      fields: %w[legal_statuses provider_life_cycle_statuses],
      with_desc: true,
      nested: {
        legal_statuses: "name",
        provider_life_cycle_statuses: "name"
      }
    }
  end

  def esfri_types
    { name: "esfri_type", template: "list", fields: %w[esfri_types], with_desc: true, nested: { esfri_types: "name" } }
  end

  def esfri_domains
    {
      name: "esfri_domain",
      template: "list",
      fields: %w[esfri_domains],
      with_desc: true,
      nested: {
        esfri_domains: "name"
      }
    }
  end

  def meril_scientific_domains
    {
      name: "meril_scientific_categorisation",
      template: "list",
      fields: %w[meril_scientific_domains],
      nested: {
        meril_scientific_domains: "name_with_parent"
      }
    }
  end

  def certifications
    { name: "certifications", template: "list", fields: %w[certifications] }
  end

  def affiliations
    { name: "affiliations", template: "list", fields: %w[affiliations] }
  end

  def structure_types
    { name: "structure_types", template: "list", fields: %w[structure_types], nested: { structure_types: "name" } }
  end

  def areas_of_activity
    {
      name: "areas_of_activity",
      template: "list",
      fields: %w[areas_of_activity],
      nested: {
        areas_of_activity: "name"
      }
    }
  end

  def societal_grand_challenges
    {
      name: "societal_grand_challenges",
      template: "list",
      fields: %w[societal_grand_challenges],
      nested: {
        societal_grand_challenges: "name"
      }
    }
  end

  def hosting_legal_entity
    {
      name: "hosting_legal_entity",
      template: "list",
      fields: %w[hosting_legal_entities],
      nested: {
        hosting_legal_entities: "name"
      }
    }
  end

  def hosting_legal_entity_string
    { name: "hosting_legal_entity", template: "array", fields: %w[hosting_legal_entity_string] }
  end

  def networks
    { name: "networks", template: "list", fields: %w[networks], nested: { networks: "name" } }
  end

  def catalogue
    { name: "catalogue", template: "list", fields: %w[catalogue], nested: { catalogue: "name" } }
  end

  def national_roadmaps
    { name: "national_roadmaps", template: "list", fields: %w[national_roadmaps] }
  end

  def monitoring_link(object)
    link_to _("Show more details"),
            "#{Mp::Application.config.monitoring_data_ui_url}/#{Mp::Application.config.monitoring_data_path}" +
              "#{object.pid.to_s.partition(".").last}/details"
  end
end
