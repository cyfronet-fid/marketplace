# frozen_string_literal: true

class Service::Ess::Add < ApplicationService
  def initialize(service, async: true)
    super()
    @service = service
    @async = async
  end

  def call
    @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
  end

  private

  def payload
    { add: { doc: ess_data }, commit: {} }.to_json
  end

  def ess_data
    {
      id: @service.id,
      pid_s: @service.pid,
      slug_s: @service.slug,
      # card
      name_t: @service.name,
      description_t: @service.description,
      rating_f: @service.rating,
      tagline_t: @service.tagline,
      resource_organisation_s: @service.resource_organisation.name,
      # filtering
      categories_ss: @service.categories.map { |category| hierarchical_to_s(category) },
      scientific_domains_ss: @service.scientific_domains.map { |domain| hierarchical_to_s(domain) },
      providers_ss: @service.providers.map(&:name),
      target_users_ss: @service.target_users.map { |target_user| hierarchical_to_s(target_user) },
      platforms_ss: @service.platforms.map(&:name),
      tags_ss: @service.tag_list,
      order_type_s: @service.order_type,
      geographical_availabilities_ss: @service.geographical_availabilities.map(&:alpha2)
    }
  end

  def hierarchical_to_s(hierarchical)
    hierarchical.ancestors.to_a.append(hierarchical).map(&:name).join(">")
  end
end
