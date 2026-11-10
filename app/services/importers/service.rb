# frozen_string_literal: true

class Importers::Service < ApplicationService
  include Importable

  def initialize(data, synchronized_at)
    super()
    @data = data
    @synchronized_at = synchronized_at
  end

  def call
    alt_pids = Array(@data["alternativePIDs"] || @data["alternativeIdentifiers"])
    subcategories =
      @data["categories"]&.map { |category| category.is_a?(Hash) ? category["subcategory"] : category } || []

    attributes = {
      pid: @data["id"],
      ppid: fetch_ppid_from_alt_pids(alt_pids).presence || fetch_ppid(alt_pids),
      alternative_identifiers: alt_pids.map { |pid| map_alt_pid(pid) || map_alternative_identifier(pid) }.compact,
      status: :published,
      synchronized_at: @synchronized_at,
      name: @data["name"],
      description: @data["description"],
      webpage_url: @data["webpage"] || "",
      logo_url: @data["logo"],
      publishing_date: @data["publishingDate"],
      resource_type: @data["type"],
      urls: Array(@data["urls"]),
      resource_organisation: map_provider(@data["resourceOwner"] || @data["resourceOrganisation"]),
      providers:
        Array(@data["serviceProviders"] || @data["resourceProviders"])
        .uniq
        .map { |provider| map_provider(provider) }
        .compact,
      nodes: map_nodes(Array(@data["nodePID"] || @data["node"])),
      scientific_domains: map_scientific_domains(scientific_domain_eids(@data["scientificDomains"])),
      categories: map_categories(subcategories) || [],
      tag_list: Array(@data["tags"]),
      access_types: map_access_types(Array(@data["accessTypes"])),
      trls: map_trl(@data["trl"]),
      jurisdiction: map_jurisdiction(@data["jurisdiction"]),
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]),
      terms_of_use_url: @data["termsOfUse"] || "",
      privacy_policy_url: @data["privacyPolicy"] || "",
      access_policies_url: @data["accessPolicy"] || "",
      order_type: map_order_type(@data["orderType"]),
      order_url: @data["order"] || ""
    }

    Mp::Variant.pl? ? attributes.merge(pl_attributes) : attributes
  end

  private

  # pl-marketplace's V5 registry mapping, added on top of the shared fields.
  def pl_attributes
    {
      abbreviation: @data["abbreviation"],
      tagline: @data["tagline"].presence || "-",
      link_multimedia_urls: Array(@data["multimedia"]).map { |item| map_link(item) }.compact,
      link_use_cases_urls: Array(@data["useCases"]).map { |item| map_link(item, "use_cases") }.compact,
      service_categories: map_service_categories(Array(@data["serviceCategories"])),
      horizontal: @data["horizontalService"] || false,
      research_activity_ids: map_research_activity_ids(@data["researchActivities"] || []),
      target_users: map_target_users(@data["targetUsers"]),
      access_modes: map_access_modes(Array(@data["accessModes"])),
      geographical_availabilities: Array(@data["geographicalAvailabilities"] || "WW"),
      language_availability: Array(@data["languageAvailabilities"]).map(&:upcase) || ["EN"],
      resource_geographic_locations: Array(@data["resourceGeographicLocations"]),
      main_contact: @data["mainContact"].present? ? MainContact.new(map_contact(@data["mainContact"])) : nil,
      public_contacts: Array(@data["publicContacts"]).map { |c| PublicContact.new(map_contact(c)) },
      helpdesk_email: @data["helpdeskEmail"] || "",
      security_contact_email: @data["securityContactEmail"] || "",
      life_cycle_statuses: map_life_cycle_status(@data["lifeCycleStatus"]),
      certifications: Array(@data["certifications"]),
      standards: Array(@data["standards"]),
      open_source_technologies: Array(@data["openSourceTechnologies"]),
      version: @data["version"] || "",
      last_update: @data["lastUpdate"],
      changelog: Array(@data["changeLog"]),
      required_services: map_related_services(Array(@data["requiredResources"])),
      related_services: map_related_services(Array(@data["relatedResources"])),
      related_platforms: Array(@data["relatedPlatforms"]),
      platforms: map_platforms(Array(@data["relatedPlatforms"])),
      catalogue: map_catalogue(@data["catalogueId"]),
      funding_bodies: map_funding_bodies(Array(@data["fundingBody"])),
      funding_programs: map_funding_programs(Array(@data["fundingPrograms"])),
      grant_project_names: Array(@data["grantProjectNames"]),
      helpdesk_url: @data["helpdeskPage"] || "",
      manual_url: @data["userManual"] || "",
      resource_level_url: @data["serviceLevel"] || "",
      training_information_url: @data["trainingInformation"] || "",
      status_monitoring_url: @data["statusMonitoring"] || "",
      maintenance_url: @data["maintenance"] || "",
      payment_model_url: @data["paymentModel"] || "",
      pricing_url: @data["pricing"] || ""
    }
  end
end
