# frozen_string_literal: true

class Importers::Datasource < ApplicationService
  include Importable

  def initialize(data, synchronized_at = Time.current)
    super()
    @data = data
    @synchronized_at = synchronized_at
  end

  def call
    attributes = common_service_fields.merge(datasource_fields)

    Mp::Variant.pl? ? attributes.merge(pl_datasource_fields) : attributes
  end

  private

  def common_service_fields
    {
      pid: @data["id"],
      ppid: fetch_ppid_from_alt_pids(alt_pids).presence || fetch_ppid(alt_pids),
      alternative_identifiers: alt_pids.map { |pid| map_alt_pid(pid) || map_alternative_identifier(pid) }.compact,
      synchronized_at: @synchronized_at,
      name: @data["name"],
      description: @data["description"],
      webpage_url: @data["webpage"] || @data["url"] || "",
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
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]),
      terms_of_use_url: @data["termsOfUse"] || "",
      privacy_policy_url: @data["privacyPolicy"] || "",
      access_policies_url: @data["accessPolicy"] || "",
      order_type: datasource_order_type,
      order_url: @data["order"] || ""
    }
  end

  def datasource_fields
    {
      version_control: @data["versionControl"] == true,
      datasource_classification: map_datasource_classification(@data["datasourceClassification"]),
      research_product_types: Array(@data["researchProductTypes"]),
      thematic: @data["thematic"] == true
    }
  end

  # pl-marketplace's V5 datasource mapping, added on top of the shared fields.
  def pl_datasource_fields
    {
      submission_policy_url: @data["submissionPolicyURL"] || "",
      preservation_policy_url: @data["preservationPolicyURL"] || "",
      persistent_identity_systems:
        Array.wrap(@data["persistentIdentitySystems"]).map { |s| map_persistent_identity_system(s, "rest") }.compact,
      research_entity_types: map_entity_types(Array(@data["researchEntityTypes"])),
      harvestable: @data["harvestable"],
      link_research_product_license_urls:
        Array.wrap(@data["researchProductLicensings"]).map { |item| map_link(item, "research_product") }.compact,
      research_product_access_policies: map_access_policies(Array(@data["researchProductAccessPolicies"])),
      link_research_product_metadata_license_urls:
        Array
        .wrap(@data["researchProductMetadataLicensing"])
        .map { |item| map_link(item, "research_product_metadata") }
        .compact,
      research_product_metadata_access_policies:
        map_metadata_access_policies(Array(@data["researchProductMetadataAccessPolicies"]))
    }
  end

  def alt_pids
    @alt_pids ||= Array(@data["alternativePIDs"] || @data["alternativeIdentifiers"])
  end

  def subcategories
    @subcategories ||=
      @data["categories"]&.map { |category| category.is_a?(Hash) ? category["subcategory"] : category } || []
  end

  def datasource_order_type
    map_order_type(@data["orderType"]) || "other"
  end
end
