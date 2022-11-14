# frozen_string_literal: true

module Datasource::Search
  extend ActiveSupport::Concern

  included do
    # ELASTICSEARCH
    # scope :search_import working with should_indexe?
    # and define which datasources are indexed in elasticsearch
    searchkick word_middle: %i[datasource_name tagline description resource_organisation_name provider_names],
               highlight: %i[datasource_name tagline description resource_organisation_name provider_names]
  end

  # search_data are definition which
  # fields are mapped to elasticsearch
  def search_data
    {
      datasource_id: id,
      datasource_name: name,
      sort_name: name.downcase,
      tagline: tagline,
      description: description,
      status: status,
      rating: nil,
      categories: categories.map(&:id),
      research_steps: research_steps&.map(&:id),
      scientific_domains: search_scientific_domains_ids,
      resource_organisation: resource_organisation,
      resource_organisation_name: resource_organisation.name,
      providers: resource_organisation_and_providers.map(&:id),
      platforms: platforms.map(&:id),
      geographical_availabilities: geographical_availabilities.map(&:alpha2),
      target_users: target_users.map(&:id),
      order_type: [order_type],
      tags: tag_list.map(&:downcase),
      source: upstream&.source_type,
      offers: [],
      offer_names: [],
      provider_names: [resource_organisation.name] << providers.map(&:name)
    }
  end

  private

  def search_scientific_domains_ids
    (scientific_domains.map(&:ancestor_ids) + scientific_domains.map(&:id)).flatten.uniq
  end
end
