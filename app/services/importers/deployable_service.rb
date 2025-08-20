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
    scientific_domains = @data["scientificDomains"]&.map { |sd| sd["scientificSubdomain"] } || []
    tag_list = Array(@data["tags"]) || []
    creators = Array(@data["creators"]) || []

    {
      pid: @data["id"],
      name: @data["name"],
      abbreviation: @data["acronym"],
      resource_organisation: map_provider(@data["resourceOrganisation"]),
      catalogue: map_catalogue(@data["catalogueId"]),
      url: @data["url"],
      node: @data["node"],
      description: @data["description"],
      tagline: @data["tagline"],
      version: @data["version"],
      last_update: @data["lastUpdate"],
      software_license: @data["softwareLicense"],
      creators: creators,
      tag_list: tag_list,
      scientific_domains: map_scientific_domains(scientific_domains),
      synchronized_at: @synchronized_at,
      status: :published
    }
  end
end
