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
             :country,
             :public_contact_emails,
             :updated_at

  attribute :created_at, key: :publication_date
  attribute :hosting_legal_entities, key: :hosting_legal_entity
  attribute :legal_statuses, key: :legal_status
  attribute :website, key: :webpage_url
  attribute :pid, key: :slug
  attribute :usage_counts_downloads do
    0
  end
  attribute :usage_counts_views
  attribute :node
end
