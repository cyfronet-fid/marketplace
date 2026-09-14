# frozen_string_literal: true

class Importers::Catalogue < ApplicationService
  include Importable

  def initialize(data, synchronized_at)
    super()
    @data = data
    @synchronized_at = synchronized_at
  end

  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  def call
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
      nodes: map_nodes(@data["node"]) || [],
      tag_list: Array(@data["tags"]) || [],
      scientific_domains:
        (
          if @data["scientificDomains"].blank?
            []
          else
            map_scientific_domains(scientific_domain_eids(@data["scientificDomains"]))
          end
        ),
      data_administrators: data_administrators,
      public_contacts: public_contacts,
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
      status: :published,
      synchronized_at: @synchronized_at
    }
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  private

  def data_administrators
    Array(@data["users"]).map { |user| DataAdministrator.new(map_data_administrator(user)) }
  end

  def public_contacts
    extract_public_contact_emails(@data["publicContacts"]).map { |email| PublicContact.new(email: email) }
  end
end
