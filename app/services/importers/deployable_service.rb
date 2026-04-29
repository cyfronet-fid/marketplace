# frozen_string_literal: true

class Importers::DeployableService < ApplicationService
  include Importable

  def initialize(data, synchronized_at, eosc_registry_base_url, token = nil)
    super()
    @data = data
    @synchronized_at = synchronized_at
    @eosc_registry_base_url = eosc_registry_base_url
    @token = token
  end

  def call
    scientific_subdomains = @data["scientificDomains"]&.map { |sd| sd["scientificSubdomain"] } || []
    urls = Array(@data["urls"])
    urls = Array(@data["url"]) if urls.blank? && @data["url"].present?
    license = @data["license"].is_a?(Hash) ? @data["license"] : {}

    {
      pid: @data["id"],
      name: @data["name"],
      abbreviation: @data["acronym"] || @data["abbreviation"],
      resource_organisation: map_provider(@data["resourceOwner"]),
      url: urls.first,
      urls: urls,
      node: Array(@data["nodePID"]).first,
      description: @data["description"],
      tagline: @data["tagline"],
      logo_url: @data["logo"],
      publishing_date: @data["publishingDate"],
      resource_type: @data["type"],
      public_contact_emails: extract_public_contact_emails(@data["publicContacts"]),
      version: @data["version"],
      last_update: @data["lastUpdate"],
      license_name: license["name"],
      license_url: license["url"],
      creators: Array(@data["creators"]),
      tag_list: Array(@data["tags"]),
      scientific_domains: map_scientific_domains(scientific_subdomains),
      synchronized_at: @synchronized_at,
      status: :published
    }
  end
end
