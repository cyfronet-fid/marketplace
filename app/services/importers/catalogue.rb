# frozen_string_literal: true

class Importers::Catalogue < ApplicationService
  include Importable

  def initialize(data, synchronized_at, source = "jms")
    super()
    @data = data
    @synchronized_at = synchronized_at
    @source = source
  end

  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def call
    format_data_for_source
    {
      name: @data["name"],
      pid: @data["id"],
      abbreviation: @data["abbreviation"] || "",
      description: @data["description"] || "",
      legal_entity: @data["legalEntity"] || false,
      legal_statuses: map_legal_statuses(Array(@data["legalStatus"])),
      website: @data["website"] || "",
      link_multimedia_urls: Array(@data["multimedia"]).map { |m| map_link(m) }.compact,
      affiliations: Array(@data["affiliations"]) || [],
      networks: map_networks(Array(@data["networks"])),
      hosting_legal_entities: map_hosting_legal_entity(@data["hostingLegalEntity"]),
      participating_countries: @data["participatingCountries"] || [],
      tags: Array(@data["tags"]) || [],
      scientific_domains: map_scientific_domains(@data["scientificDomains"].map { |sd| sd["scientificSubdomain"] }),
      public_contacts: Array(@data["publicContacts"]).map { |c| PublicContact.new(map_contact(c)) },
      main_contact: @data["mainContact"] ? MainContact.new(map_contact(@data["mainContact"])) : nil,
      street_name_and_number: @data.dig("location", "streetNameAndNumber") || "",
      postal_code: @data.dig("location", "postalCode") || "",
      city: @data.dig("location", "city") || "",
      region: @data.dig("location", "region") || "",
      country: @data.dig("location", "country") || "",
      inclusion_criteria: @data["inclusionCriteria"] || "",
      validation_process: @data["validationProcess"] || "",
      end_of_life: @data["endOfLife"] || "",
      scope: @data["scope"],
      data_administrators: @data["users"]&.map { |da| DataAdministrator.new(map_data_administrator(da)) },
      status: :published,
      synchronized_at: @synchronized_at
    }
  end

  def format_data_for_source
    return unless @source == "jms"

    @data["multimedia"] = Array.wrap(@data.dig("multimedia", "multimedia")) || []
    @data["affiliations"] = Array(@data.dig("affiliations", "affiliation")) || []
    @data["networks"] = Array(@data.dig("networks", "network")) || []
    @data["hostingLegalEntity"] = Array(@data["hostingLegalEntity"]) || []
    @data["participatingCountries"] = Array(@data.dig("participatingCountries", "participatingCountry")) || []
    @data["tags"] = Array(@data.dig("tags", "tag")) || []
    @data["publicContacts"] = Array.wrap(@data.dig("publicContacts", "publicContact"))
    @data["scientificDomains"] = Array
      .wrap(@data.dig("scientificDomains", "scientificDomain"))
      .map { |sd| sd["scientificSubdomain"] } || []
    @data["users"] = Array.wrap(@data.dig("users", "user")) || []
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
end
