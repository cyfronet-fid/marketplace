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

    {
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
  end
end
