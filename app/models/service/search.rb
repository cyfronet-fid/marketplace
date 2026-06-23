# frozen_string_literal: true

module Service::Search
  extend ActiveSupport::Concern

  included do
    searchkick word_middle: %i[name description offer_names resource_organisation_name provider_names node_names],
               highlight: %i[name resource_organisation_name provider_names]
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
    }
  end

  private

  def search_scientific_domains_ids
    (scientific_domains.map(&:ancestor_ids) + scientific_domains.map(&:id)).flatten.uniq
  end
end
