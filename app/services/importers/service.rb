# frozen_string_literal: true

class Importers::Service < ApplicationService
  include Importable

  def initialize(data, synchronized_at, eosc_registry_base_url, token = nil)
    super()
    @data = data
    @synchronized_at = synchronized_at
    @eosc_registry_base_url = eosc_registry_base_url
    @token = token
  end

  def call
    alt_pids = Array(@data["alternativePIDs"] || @data["alternativeIdentifiers"])
    scientific_subdomains = @data["scientificDomains"]&.map { |sd| sd["scientificSubdomain"] } || []
    subcategories = @data["categories"]&.map { |category| category["subcategory"] } || []

    {
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
      scientific_domains: map_scientific_domains(scientific_subdomains),
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
  end
end
