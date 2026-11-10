# frozen_string_literal: true

class Importers::Catalogue < ApplicationService
  include Importable

  def initialize(data, synchronized_at)
    super()

    @data = data
    @synchronized_at = synchronized_at
  end

  def call
    attributes = {
      pid: data["id"],
      name: data["name"],
      description: data["description"],
      website: data["webpage"],
      tag_list: Array(data["tags"]),
      scientific_domains: scientific_domains,
      public_contacts: public_contacts,
      main_contact: main_contact,
      status: :published,
      synchronized_at: synchronized_at
    }

    Mp::Variant.pl? ? attributes.merge(pl_attributes) : attributes
  end

  private

  attr_reader :data, :synchronized_at

  # pl-marketplace's V5 registry mapping, added on top of the shared fields.
  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def pl_attributes
    {
      abbreviation: data["abbreviation"] || "",
      description: data["description"] || "",
      legal_entity: data["legalEntity"] || false,
      legal_statuses: map_legal_statuses(Array(data["legalStatus"])),
      website: data["website"] || "",
      link_multimedia_urls: Array(data["multimedia"]).map { |m| map_link(m) }.compact,
      affiliations: Array(data["affiliations"]),
      networks: map_networks(Array(data["networks"])),
      hosting_legal_entities: map_hosting_legal_entity(data["hostingLegalEntity"]),
      participating_countries: data["participatingCountries"] || [],
      nodes: map_nodes(data["node"]),
      public_contacts: Array(data["publicContacts"]).map { |c| PublicContact.new(map_contact(c)) },
      street_name_and_number: data.dig("location", "streetNameAndNumber") || "",
      postal_code: data.dig("location", "postalCode") || "",
      city: data.dig("location", "city") || "",
      region: data.dig("location", "region") || "",
      country: data.dig("location", "country") || "",
      inclusion_criteria: data["inclusionCriteria"] || "",
      validation_process: data["validationProcess"] || "",
      end_of_life: data["endOfLife"] || "",
      scope: data["scope"],
      data_administrators: Array(data["users"]).map { |da| DataAdministrator.new(map_data_administrator(da)) }
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  def main_contact
    return unless data["mainContact"].is_a?(Hash)

    contact_attributes = map_contact(data["mainContact"])
    MainContact.new(contact_attributes)
  end

  def public_contacts
    contact_emails = extract_public_contact_emails(data["publicContacts"])
    contact_emails.map { |email| PublicContact.new(email: email) }
  end

  def scientific_domains
    eids = scientific_domain_eids(data["scientificDomains"])
    map_scientific_domains(eids)
  end
end
