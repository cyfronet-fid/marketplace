# frozen_string_literal: true

class Importers::Provider < ApplicationService
  include Importable

  def initialize(data, synchronized_at)
    super()
    @data = data
    @synchronized_at = synchronized_at
  end

  def call
    alt_pids = Array(@data["alternativePIDs"])
    multimedia = Array(@data["multimedia"])

    attributes = {
      pid: @data["id"],
      name: @data["name"],
      abbreviation: @data["abbreviation"],
      website: @data["website"],
      country: Country.for(@data["country"])&.alpha2 || "",
      legal_entity: @data["legalEntity"],
      legal_statuses: map_legal_statuses(Array(@data["legalStatus"])),
      hosting_legal_entities: map_hosting_legal_entity(Array(@data["hostingLegalEntity"])),
      description: @data["description"],
      nodes: map_nodes(Array(@data["nodePID"])),
      link_multimedia_urls: multimedia.map { |m| map_link(m) }.compact,
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]),
      alternative_identifiers: alt_pids.map { |p| map_alt_pid(p) }.compact,
      ppid: fetch_ppid_from_alt_pids(alt_pids),
      synchronized_at: @synchronized_at,
      status: :published
    }

    Mp::Variant.pl? ? attributes.merge(pl_attributes) : attributes
  end

  private

  # pl-marketplace's V5 registry mapping, added on top of the shared fields.
  def pl_attributes
    alternative_identifiers = Array(@data["alternativeIdentifiers"])
    location = @data["location"] || {}

    {
      alternative_identifiers: alternative_identifiers.map { |aid| map_alternative_identifier(aid) }.compact,
      ppid: fetch_ppid(alternative_identifiers),
      nodes: map_nodes(@data["node"]),
      hosting_legal_entity_string: @data["hostingLegalEntity"],
      scientific_domains: map_scientific_domains(@data["scientificDomains"]&.map do |sd|
        sd["scientificSubdomain"]
      end || []),
      tag_list: Array(@data["tags"]),
      street_name_and_number: location["streetNameAndNumber"],
      postal_code: location["postalCode"],
      city: location["city"],
      region: location["region"],
      country: Country.for(location["country"])&.alpha2,
      main_contact: @data["mainContact"].present? ? MainContact.new(map_contact(@data["mainContact"])) : nil,
      public_contacts: Array(@data["publicContacts"]).map { |c| PublicContact.new(map_contact(c)) },
      provider_life_cycle_statuses: map_provider_life_cycle_status(@data["lifeCycleStatus"]),
      certifications: Array(@data["certifications"]),
      participating_countries: Array(@data["participatingCountries"]),
      affiliations: Array(@data["affiliations"]),
      networks: map_networks(Array(@data["networks"])),
      catalogue: map_catalogue(@data["catalogueId"]),
      structure_types: map_structure_types(Array(@data["structureTypes"])),
      esfri_domains: map_esfri_domains(Array(@data["esfriDomains"])),
      esfri_types: map_esfri_types(@data["esfriType"]),
      meril_scientific_domains:
        map_meril_scientific_domains(@data["merilScientificDomains"]&.map do |sd|
          sd["merilScientificSubdomain"]
        end || []),
      areas_of_activity: map_areas_of_activity(@data["areasOfActivity"]),
      societal_grand_challenges: map_societal_grand_challenges(Array(@data["societalGrandChallenges"])),
      national_roadmaps: Array(@data["nationalRoadmaps"]),
      data_administrators: Array(@data["users"]).map { |da| DataAdministrator.new(map_data_administrator(da)) }
    }
  end
end
