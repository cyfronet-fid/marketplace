# frozen_string_literal: true

class Ess::ProviderSerializer < ApplicationSerializer
  attributes :id,
             :pid,
             :catalogues,
             :name,
             :abbreviation,
             :legal_entity,
             :description,
             :multimedia_urls,
             :scientific_domains,
             :tag_list,
             :structure_types,
             :street_name_and_number,
             :postal_code,
             :city,
             :region,
             :country,
             :public_contacts,
             :certifications,
             :participating_countries,
             :networks,
             :affiliations,
             :esfri_domains,
             :meril_scientific_domains,
             :areas_of_activity,
             :societal_grand_challenges,
             :national_roadmaps,
             :updated_at

  attribute :created_at, key: :publication_date
  attribute :hosting_legal_entities, key: :hosting_legal_entity
  attribute :provider_life_cycle_statuses, key: :provider_life_cycle_status
  attribute :esfri_types, key: :esfri_type
  attribute :legal_statuses, key: :legal_status
  attribute :website, key: :webpage_url
  attribute :pid, key: :slug
  attribute :usage_counts_downloads do
    0
  end
  attribute :usage_counts_views
  attribute :node

  def tag_list
    object.tag_list
  end
end
