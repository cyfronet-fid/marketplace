# frozen_string_literal: true

class Recommender::ServiceSerializer < ActiveModel::Serializer
  attributes :id, :pid, :name, :description, :tagline, :countries, :order_type, :rating, :status, :horizontal
  attribute :category_ids, key: :categories
  attribute :provider_ids, key: :providers
  attribute :resource_organisation_id, key: :resource_organisation
  attribute :scientific_domain_ids, key: :scientific_domains
  attribute :platform_ids, key: :platforms
  attribute :target_user_ids, key: :target_users
  attribute :access_mode_ids, key: :access_modes
  attribute :access_type_ids, key: :access_types
  attribute :research_activity_ids, key: :research_activities
  attribute :trl_ids, key: :trls
  attribute :life_cycle_status_ids, key: :life_cycle_statuses
  attribute :required_service_ids, key: :required_services
  attribute :related_services

  def countries
    object.geographical_availabilities.map(&:alpha2)
  end

  def related_services
    (object.related_service_ids + object.manual_related_service_ids).uniq
  end
end
