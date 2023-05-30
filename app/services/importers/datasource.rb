# frozen_string_literal: true

class Importers::Datasource < ApplicationService
  include Importable

  def initialize(data, synchronized_at, eosc_registry_base_url, token = nil, source = "jms")
    super()
    @data = data
    @synchronized_at = synchronized_at
    @source = source
    @eosc_registry_base_url = eosc_registry_base_url
    @token = token
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def call
    case @source
    when "jms"
      providers = Array(@data.dig("resourceProviders", "resourceProvider"))
      multimedia =
        if @data.dig("multimedia", "multimedia").is_a?(Array)
          Array(@data.dig("multimedia", "multimedia")) || []
        else
          [@data.dig("multimedia", "multimedia")] || []
        end
      use_cases_url =
        if @data.dig("useCases", "useCase").is_a?(Array)
          Array(@data.dig("useCases", "useCase")) || []
        else
          [@data.dig("useCases", "useCase")] || []
        end
      link_rpl_url =
        if @data.dig("researchProductLicensings", "researchProductLicensing").is_a?(Array)
          Array(@data.dig("researchProductLicensings", "researchProductLicensing")) || []
        else
          [@data.dig("researchProductLicensings", "researchProductLicensing")] || []
        end
      link_rpml_url =
        if @data.dig("researchProductMetadataLicensings", "researchProductMetadataLicense").is_a?(Array)
          Array(@data.dig("researchProductMetadataLicensings", "researchProductMetadataLicense")) || []
        else
          [@data["researchProductMetadataLicensing"]] || []
        end
      scientific_domains =
        if @data.dig("scientificDomains", "scientificDomain").is_a?(Array)
          @data.dig("scientificDomains", "scientificDomain")&.map { |sd| sd["scientificSubdomain"] }
        else
          @data.dig("scientificDomains", "scientificDomain", "scientificSubdomain")
        end
      categories =
        if @data.dig("categories", "category").is_a?(Array)
          @data.dig("categories", "category")&.map { |c| c["subcategory"] }
        else
          @data.dig("categories", "category", "subcategory")
        end
      target_users = @data.dig("targetUsers", "targetUser")
      access_types = Array(@data.dig("accessTypes", "accessType"))
      access_modes = Array(@data.dig("accessModes", "accessMode"))
      tag_list = Array(@data.dig("tags", "tag")) || []
      geographical_availabilities = Array(@data.dig("geographicalAvailabilities", "geographicalAvailability") || "WW")
      language_availability = Array(@data.dig("languageAvailabilities", "languageAvailability")).map(&:upcase) || ["EN"]
      resource_geographic_locations =
        Array(@data.dig("resourceGeographicLocations", "resourceGeographicLocation")) || []
      public_contacts =
        Array.wrap(@data.dig("publicContacts", "publicContact"))&.map { |c| PublicContact.new(map_contact(c)) } || []
      certifications = Array(@data.dig("certifications", "certification")) || []
      standards = Array(@data.dig("standards", "standard")) || []
      open_source_technologies = Array(@data.dig("openSourceTechnologies", "openSourceTechnology")) || []
      last_update = @data["lastUpdate"].present? ? Time.at(@data["lastUpdate"].to_i) : nil
      changelog = Array(@data.dig("changeLog", "changeLog")) || []
      required_services = map_related_services(Array(@data.dig("requiredResources", "requiredResource"))) || []
      related_services = map_related_services(Array(@data.dig("relatedResources", "relatedResource"))) || []
      platforms = map_platforms(Array(@data.dig("relatedPlatforms", "relatedPlatform"))) || []
      funding_bodies = map_funding_bodies(@data.dig("fundingBody", "fundingBody")) || []
      funding_programs = map_funding_programs(@data.dig("fundingPrograms", "fundingProgram")) || []
      grant_project_names = Array(@data.dig("grantProjectNames", "grantProjectName")) || []
      persistent_identity_systems =
        if @data.dig("persistentIdentitySystems", "persistentIdentitySystem").is_a?(Array)
          Array(@data.dig("persistentIdentitySystems", "persistentIdentitySystem")) || []
        else
          [@data.dig("persistentIdentitySystems", "persistentIdentitySystem")] || []
        end
      entity_types = map_entity_types(@data.dig("researchEntityTypes", "researchEntityType"))
      research_product_access_policies = @data.dig("researchProductAccessPolicies", "researchProductAccessPolicy") || []
      research_product_metadata_access_policies =
        @data.dig("researchProductMetadataAccessPolicies", "researchProductMetadataAccessPolicy") || []
      research_steps =
        if @data.dig("researchCategories", "researchCategory").present?
          Array(@data.dig("researchCategories", "researchCategory"))
        else
          []
        end
    when "rest"
      providers = Array(@data["resourceProviders"]) || []
      multimedia = Array(@data["multimedia"]) || []
      use_cases_url = Array(@data["useCases"]) || []
      scientific_domains = @data["scientificDomains"]&.map { |sd| sd["scientificSubdomain"] } || []
      categories = @data["categories"]&.map { |c| c["subcategory"] } || []
      target_users = @data["targetUsers"]
      access_types = Array(@data["accessTypes"])
      access_modes = Array(@data["accessModes"])
      tag_list = Array(@data["tags"]) || []
      geographical_availabilities = Array(@data["geographicalAvailabilities"] || ["WW"]).compact
      language_availability = @data["languageAvailabilities"]&.map(&:upcase)&.compact || ["EN"]
      resource_geographic_locations = Array(@data["resourceGeographicLocations"] || []).compact
      public_contacts = Array(@data["publicContacts"])&.map { |c| PublicContact.new(map_contact(c)) } || []
      certifications = Array(@data["certifications"])
      standards = Array(@data["standards"])
      open_source_technologies = Array(@data["openSourceTechnologies"])
      last_update = @data["lastUpdate"]
      changelog = Array(@data["changeLog"])
      required_services = map_related_services(Array(@data["requiredResources"]))
      related_services = map_related_services(Array(@data["relatedResources"]))
      platforms = map_platforms(Array(@data["relatedPlatforms"]))
      funding_bodies = map_funding_bodies(Array(@data["fundingBody"]))
      funding_programs = map_funding_programs(Array(@data["fundingPrograms"]))
      grant_project_names = Array(@data["grantProjectNames"])
      persistent_identity_systems = Array(@data["persistentIdentitySystems"] || [])
      link_rpl_url =
        if @data["researchProductLicensings"].is_a?(Array)
          @data["researchProductLicensings"]
        else
          [@data["researchProductLicensings"]] || []
        end
      link_rpml_url =
        if @data["researchProductMetadataLicensing"].is_a?(Array)
          @data["researchProductMetadataLicensing"]
        else
          [@data["researchProductMetadataLicensing"]] || []
        end
      entity_types = map_entity_types(Array(@data["researchEntityTypes"]) || [])
      research_product_access_policies = @data["researchProductMetadataAccessPolicies"] || []
      research_product_metadata_access_policies = @data["researchProductMetadataAccessPolicies"] || []
      research_steps = @data["researchCategories"] || []
    end

    status = @data["status"] || ENV["RESOURCE_IMPORT_STATUS"] || "published"

    main_contact = MainContact.new(map_contact(@data["mainContact"])) if @data["mainContact"]

    {
      pid: @data["id"],
      # Basic
      name: @data["name"],
      abbreviation: @data["abbreviation"],
      resource_organisation: map_provider(@data["resourceOrganisation"]),
      providers: providers.uniq&.map { |p| map_provider(p) }&.compact || [],
      webpage_url: @data["webpage"] || "",
      # Marketing
      description: @data["description"],
      tagline: @data["tagline"].blank? ? "-" : @data["tagline"],
      link_multimedia_urls: multimedia&.map { |item| map_link(item) }&.compact || [],
      link_use_cases_urls: use_cases_url&.map { |item| map_link(item, "use_cases") }&.compact || [],
      # Classification
      scientific_domains: map_scientific_domains(scientific_domains) || [],
      categories: map_categories(categories) || [],
      research_step_ids: map_research_step_ids(research_steps) || [],
      horizontal: @data["horizontalService"] || false,
      target_users: map_target_users(target_users) || [],
      access_types: map_access_types(access_types) || [],
      access_modes: map_access_modes(access_modes) || [],
      tag_list: tag_list,
      # Availability
      geographical_availabilities: geographical_availabilities,
      language_availability: language_availability,
      # Location
      resource_geographic_locations: resource_geographic_locations,
      # Contact
      main_contact: main_contact,
      public_contacts: public_contacts || [],
      helpdesk_email: @data["helpdeskEmail"] || "",
      security_contact_email: @data["securityContactEmail"] || "",
      # Maturity
      trls: map_trl(@data["trl"]) || [],
      life_cycle_statuses: map_life_cycle_status(@data["lifeCycleStatus"]) || [],
      certifications: certifications,
      standards: standards,
      open_source_technologies: open_source_technologies,
      version: @data["version"] || "",
      last_update: last_update,
      changelog: changelog,
      # Dependencies
      required_services: required_services,
      related_services: related_services,
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
      resource_level_url: @data["resourceLevel"] || "",
      training_information_url: @data["trainingInformation"] || "",
      status_monitoring_url: @data["statusMonitoring"] || "",
      maintenance_url: @data["maintenance"] || "",
      # Order
      order_type: map_order_type(@data["orderType"]) || "other",
      order_url: @data["order"] || "",
      # Financial
      payment_model_url: @data["paymentModel"] || "",
      pricing_url: @data["pricing"] || "",
      # Datasource policies
      submission_policy_url: @data["submissionPolicyURL"] || "",
      preservation_policy_url: @data["preservationPolicyURL"] || "",
      version_control: @data["versionControl"] || false,
      persistent_identity_systems:
        persistent_identity_systems&.map { |s| map_persistent_identity_system(s, @source) }&.compact || [],
      jurisdiction: map_jurisdiction(@data["jurisdiction"]) || nil,
      datasource_classification: map_datasource_classification(@data["datasourceClassification"]) || nil,
      research_entity_types: entity_types,
      thematic: @data["thematic"],
      # Research product policies
      link_research_product_license_urls:
        link_rpl_url&.map { |item| map_link(item, "research_product") }&.compact || [],
      research_product_access_policies: map_access_policies(research_product_access_policies) || [],
      link_research_product_metadata_license_urls:
        link_rpml_url&.map { |item| map_link(item, "research_product_metadata") }&.compact || [],
      research_product_metadata_access_policies:
        map_metadata_access_policies(research_product_metadata_access_policies) || [],
      status: status,
      synchronized_at: @synchronized_at
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
end
