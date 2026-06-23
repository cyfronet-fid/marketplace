# frozen_string_literal: true

class Recommender::ServiceSerializer < ActiveModel::Serializer
  attributes :id, :pid, :name, :description, :order_type, :rating, :status
  attribute :category_ids, key: :categories
  attribute :provider_ids, key: :providers
  attribute :resource_organisation_id, key: :resource_organisation
  attribute :scientific_domain_ids, key: :scientific_domains
  attribute :access_type_ids, key: :access_types
  attribute :trl_ids, key: :trls
end
