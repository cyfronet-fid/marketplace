# frozen_string_literal: true

class Recommender::UserSerializer < ActiveModel::Serializer
  attribute :id
  attribute :uid, key: :aai_uid
  attribute :scientific_domain_ids, key: :scientific_domains
  attribute :category_ids, key: :categories
  attribute :accessed_services

  def accessed_services
    User
      .joins(projects: [project_items: [offer: [:service]]])
      .order("project_items.created_at")
      .where("users.email = ?", object.email)
      .pluck("services.id")
  end
end
