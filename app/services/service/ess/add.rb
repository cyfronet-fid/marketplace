# frozen_string_literal: true

class Service::Ess::Add < ApplicationService
  def initialize(service, async: true, dry_run: false)
    super()
    @service = service
    @type = service.type == "Datasource" ? "data source" : "service"
    @async = async
    @dry_run = dry_run
  end

  def call
    if @dry_run
      ess_data
    else
      @service.offers.each(&:save) unless @service.offers.published.size.zero?
      @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
    end
  end

  private

  def payload
    { action: "update", data_type: @type, data: ess_data }.as_json
  end

  def ess_data # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    different =
      if @service.type == "Datasource"
        {
          resource_level_url: @service.resource_level_url,
          persistent_identity_systems:
            @service.persistent_identity_systems&.map do |p|
              { entity_type: p.entity_type.name, entity_type_schemes: p.entity_type_schemes&.map(&:name) }
            end
        }
      else
        { sla_url: @service.resource_level_url, slug: @service.slug }
      end
    {
      id: @service.id,
      pid: @service.pid,
      catalogue: @service.catalogue&.name,
      abbreviation: @service.abbreviation,
      name: @service.name,
      tagline: @service.tagline,
      description: @service.description,
      order_type: @service.order_type,
      categories: @service.categories&.map { |category| hierarchical_to_s(category) },
      scientific_domains: @service.scientific_domains&.map { |sd| hierarchical_to_s(sd) },
      resource_organisation: @service.resource_organisation.name,
      providers: @service.providers&.map(&:name),
      multimedia_urls: @service.link_multimedia_urls&.map { |m| { name: m.name, url: m.url } },
      use_cases_urls: @service.link_use_cases_urls&.map { |m| { name: m.name, url: m.url } },
      access_types: @service.access_types&.map(&:name),
      access_modes: @service.access_modes&.map(&:name),
      platforms: @service.platforms&.map(&:name),
      related_platforms: @service.related_platforms,
      funding_bodies: @service.funding_bodies&.map(&:name),
      funding_programs: @service.funding_programs&.map(&:name),
      dedicated_for: @service.target_users.map(&:name),
      resource_geographic_locations: @service.resource_geographic_locations&.map(&:iso_short_name),
      geographical_availabilities: @service.geographical_availabilities&.map(&:iso_short_name),
      language_availability: @service.languages,
      public_contacts: @service.public_contacts&.map(&:as_json),
      trl: @service.trl.first&.name,
      life_cycle_status: @service.life_cycle_status.first&.name,
      status: @service.status,
      phase: @service.phase,
      version: @service.version,
      terms_of_use_url: @service.terms_of_use_url,
      training_information_url: @service.training_information_url,
      access_policies_url: @service.access_policies_url,
      maintenance_url: @service.maintenance_url,
      webpage_url: @service.webpage_url,
      manual_url: @service.manual_url,
      helpdesk_url: @service.helpdesk_url,
      helpdesk_email: @service.helpdesk_email,
      pricing_url: @service.pricing_url,
      privacy_policy_url: @service.privacy_policy_url,
      activate_message: @service.activate_message,
      restrictions: @service.restrictions,
      security_contact_email: @service.security_contact_email,
      certifications: @service.certifications,
      status_monitoring_url: @service.status_monitoring_url,
      standards: @service.standards,
      open_source_technologies: @service.open_source_technologies,
      grant_project_names: @service.grant_project_names,
      order_url: @service.order_url,
      payment_model_url: @service.payment_model_url,
      changelog: @service.changelog,
      tag_list: @service.tag_list,
      last_update: @service.last_update,
      upstream_id: @service.upstream_id,
      created_at: @service.created_at,
      updated_at: @service.updated_at,
      synchronized_at: @service.synchronized_at,
      rating: @service.rating,
      offers_count: @service.offers_count,
      project_items_count: @service.project_items_count,
      service_opinion_count: @service.service_opinion_count,
      horizontal: @service.horizontal || false,
      unified_categories: @service.research_steps&.map(&:name) || []
    }.merge(different)
  end
end
