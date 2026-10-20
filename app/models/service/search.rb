# frozen_string_literal: true

module Service::Search
  extend ActiveSupport::Concern

  included do
    word_middle_fields = %i[name description offer_names resource_organisation_name provider_names node_names]
    highlight_fields = %i[name resource_organisation_name provider_names]

    if Mp::Variant.pl?
      word_middle_fields << :tagline
      highlight_fields << :tagline
    end

    searchkick word_middle: word_middle_fields, highlight: highlight_fields
  end

  def search_data
    {
      service_id: id,
      name: name,
      sort_name: name&.downcase,
      description: description,
      status: status,
      rating: rating,
      categories: categories.map(&:id),
      scientific_domains: search_scientific_domains_ids,
      resource_organisation_name: resource_organisation.name,
      providers: resource_organisation_and_providers.map(&:id),
      order_type: [order_type] << offers.published.map(&:order_type),
      tags: tag_list.map(&:downcase),
      source: upstream&.source_type,
      offers: offers.ids,
      offer_names: offers.map(&:name),
      provider_names: [resource_organisation.name] << providers.map(&:name),
      node_names: nodes.map(&:name),
      jurisdiction: jurisdiction&.eid,
      datasource_classification: datasource_classification&.eid,
      version_control: version_control,
      thematic: thematic,
      research_product_types: research_product_types,
      publishing_date: publishing_date,
      resource_type: resource_type,
      urls: urls
    }.merge(pl_only_search_data)
  end

  private

  def search_scientific_domains_ids
    (scientific_domains.map(&:ancestor_ids) + scientific_domains.map(&:id)).flatten.uniq
  end

  # Keep the two V6 variants' index shape unchanged. These fields preserve
  # pl-marketplace's pre-V6 search behavior and are backed by PL-only profile
  # data or associations retained from that database.
  def pl_only_search_data
    return {} unless Mp::Variant.pl?

    {
      tagline: tagline,
      geographical_availabilities: Array(geographical_availabilities).map(&:alpha2),
      research_activities: research_activities.map(&:id),
      platforms: platforms.map(&:id),
      dedicated_for: target_users.map(&:id)
    }
  end
end
