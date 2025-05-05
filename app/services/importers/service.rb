# frozen_string_literal: true

class Importers::Service < ApplicationService
  include Importable

  def initialize(data, synchronized_at, eosc_registry_base_url, token = nil, source = "jms")
    super()
    @data = data
    @synchronized_at = synchronized_at
    @source = source
    @eosc_registry_base_url = eosc_registry_base_url
    @token = token
  end

  def call
    alternative_identifiers = Array(@data["alternativeIdentifiers"]) || []
    providers = Array(@data["resourceProviders"]) || []
    multimedia = Array(@data["multimedia"]) || []
    use_cases_url = Array(@data["useCases"]) || []
    scientific_domains = @data["scientificDomains"]&.map { |sd| sd["scientificSubdomain"] } || []
    service_categories = Array(@data["serviceCategories"]) || []
    categories = @data["categories"]&.map { |c| c["subcategory"] } || []
    target_users = @data["targetUsers"]
    access_types = Array(@data["accessTypes"])
    access_modes = Array(@data["accessModes"])
    tag_list = Array(@data["tags"]) || []
    geographical_availabilities = Array(@data["geographicalAvailabilities"] || "WW")
    language_availability = @data["languageAvailabilities"]&.map(&:upcase) || ["EN"]
    resource_geographic_locations = Array(@data["resourceGeographicLocations"]) || []
    public_contacts = Array(@data["publicContacts"])&.map { |c| PublicContact.new(map_contact(c)) } || []
    certifications = Array(@data["certifications"])
    standards = Array(@data["standards"])
    open_source_technologies = Array(@data["openSourceTechnologies"])
    last_update = @data["lastUpdate"]
    changelog = Array(@data["changeLog"])
    required_services = map_related_services(Array(@data["requiredResources"]))
    related_services = map_related_services(Array(@data["relatedResources"]))
    related_platforms = Array(@data["relatedPlatforms"]) || []
    platforms = map_platforms(Array(@data["relatedPlatforms"]))
    funding_bodies = map_funding_bodies(Array(@data["fundingBody"]))
    funding_programs = map_funding_programs(Array(@data["fundingPrograms"]))
    grant_project_names = Array(@data["grantProjectNames"]) || []
    marketplace_locations = @data["marketplaceLocations"] || []

    main_contact = @data["mainContact"].present? ? MainContact.new(map_contact(@data["mainContact"])) : nil

    {
      alternative_identifiers: alternative_identifiers.map { |aid| map_alternative_identifier(aid) }.compact,
      ppid: fetch_ppid(alternative_identifiers),
      status: @data["status"],
      pid: @data["id"],
      # Basic
      name: @data["name"],
      abbreviation: @data["abbreviation"],
      resource_organisation: map_provider(@data["resourceOrganisation"]),
      providers: providers.uniq.map { |p| map_provider(p) }.compact,
      webpage_url: @data["webpage"] || "",
      # Marketing
      description: @data["description"],
      tagline: @data["tagline"].blank? ? "-" : @data["tagline"],
      nodes: map_nodes(@data["node"]),
      link_multimedia_urls: multimedia.map { |item| map_link(item) }.compact,
      link_use_cases_urls: use_cases_url.map { |item| map_link(item, "use_cases") }.compact,
      # Classification
      scientific_domains: map_scientific_domains(scientific_domains),
      service_categories: map_service_categories(service_categories),
      categories: map_categories(categories) || [],
      horizontal: @data["horizontalService"] || false,
      marketplace_location_ids: map_marketplace_location_ids(marketplace_locations),
      target_users: map_target_users(target_users),
      access_types: map_access_types(access_types),
      access_modes: map_access_modes(access_modes),
      tag_list: tag_list,
      # Availability
      geographical_availabilities: geographical_availabilities,
      language_availability: language_availability,
      # Location
      resource_geographic_locations: resource_geographic_locations,
      # Contact
      main_contact: main_contact,
      public_contacts: public_contacts,
      helpdesk_email: @data["helpdeskEmail"] || "",
      security_contact_email: @data["securityContactEmail"] || "",
      # Maturity
      trls: map_trl(@data["trl"]),
      life_cycle_statuses: map_life_cycle_status(@data["lifeCycleStatus"]),
      certifications: certifications,
      standards: standards,
      open_source_technologies: open_source_technologies,
      version: @data["version"] || "",
      last_update: last_update,
      changelog: changelog,
      # Dependencies
      required_services: required_services,
      related_services: related_services,
      related_platforms: related_platforms,
      platforms: platforms,
      catalogue: map_catalogue(@data["catalogueId"]),
      # Attribution
      funding_bodies: funding_bodies,
      funding_programs: funding_programs,
      grant_project_names: grant_project_names,
      # Management
      helpdesk_url: @data["helpdeskPage"] || "",
      manual_url: @data["userManual"] || "",
      terms_of_use_url: @data["termsOfUse"] || "",
      privacy_policy_url: @data["privacyPolicy"] || "",
      access_policies_url: @data["accessPolicy"] || "",
      resource_level_url: @data["serviceLevel"] || "",
      training_information_url: @data["trainingInformation"] || "",
      status_monitoring_url: @data["statusMonitoring"] || "",
      maintenance_url: @data["maintenance"] || "",
      # Order
      order_type: map_order_type(@data["orderType"]),
      order_url: @data["order"] || "",
      # Financial
      payment_model_url: @data["paymentModel"] || "",
      pricing_url: @data["pricing"] || "",
      synchronized_at: @synchronized_at
    }
  end
end
