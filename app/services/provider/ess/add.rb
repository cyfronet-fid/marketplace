# frozen_string_literal: true

class Provider::Ess::Add < ApplicationService
  def initialize(provider, async: true, dry_run: false)
    super()
    @provider = provider # TODO: Change payload to the new format here
    @type = "provider"
    @async = async
    @dry_run = dry_run
  end

  def call
    if @dry_run
      ess_data
    else
      @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
    end
  end

  private

  def payload
    { action: "update", data_type: @type, data: ess_data }.as_json
  end

  def ess_data # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    {
      id: @provider.id,
      pid: @provider.pid,
      catalogue: @provider.catalogue&.name,
      slug: @provider.pid,
      name: @provider.name,
      abbreviation: @provider.abbreviation,
      webpage_url: @provider.website,
      legal_entity: @provider.legal_entity,
      legal_status: @provider.legal_statuses.first&.name,
      hosting_legal_entity: @provider.hosting_legal_entities&.first&.name,
      description: @provider.description,
      multimedia_urls: @provider.link_multimedia_urls&.map { |m| { name: m.name, url: m.url } },
      scientific_domains: @provider.scientific_domains&.map { |sd| hierarchical_to_s(sd) },
      tag_list: @provider.tag_list,
      structure_types: @provider.structure_types&.map(&:name),
      street_name_and_number: @provider.street_name_and_number,
      postal_code: @provider.postal_code,
      city: @provider.city,
      region: @provider.region,
      country: @provider.country.iso_short_name,
      public_contacts: @provider.public_contacts&.map(&:as_json),
      provider_life_cycle_status: @provider.provider_life_cycle_statuses&.first&.name,
      certifications: @provider.certifications,
      participating_countries: @provider.participating_countries&.map(&:iso_short_name),
      affiliations: @provider.affiliations,
      networks: @provider.networks&.map(&:name),
      esfri_domains: @provider.esfri_domains&.map(&:name),
      esfri_type: @provider.esfri_types&.first&.name,
      meril_scientific_domains: @provider.meril_scientific_domains&.map(&:name),
      areas_of_activity: @provider.areas_of_activity&.map(&:name),
      societal_grand_challenges: @provider.societal_grand_challenges&.map(&:name),
      national_roadmaps: @provider.national_roadmaps
    }
  end
end
