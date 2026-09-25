# frozen_string_literal: true

class Catalogue::ServiceSerializer < ApplicationSerializer
  attribute :pid, key: :id
  attribute :webpage_url, key: :webpage
  attribute :tag_list, key: :tags
  attribute :language_availability, key: :language_availabilities
  attribute :trls, key: :trl
  attribute :manual_url, key: :user_manual
  attribute :terms_of_use_url, key: :terms_of_use
  attribute :privacy_policy_url, key: :privacy_policy
  attribute :access_policies_url, key: :access_policy
  attribute :order_type do
    "order_type-#{object.order_type}"
  end

  attribute :logo_url, key: :logo
  attribute :alternative_identifiers do
    object.alternative_identifiers.map { |a| Catalogue::AlternativeIdentifierSerializer.new(a).as_json }
  end

  attributes :abbreviation,
             :name,
             :description,
             :tagline,
             :target_users,
             :access_modes,
             :helpdesk_email,
             :security_contact_email,
             :scientific_domains,
             :categories

  # Produce camelCase keys as required by the catalogue schema
  def as_json(*)
    camelize_keys_deep(super)
  end

  %i[target_users access_modes].each do |method|
    define_method method do
      object.send(method)&.map(&:eid)
    end
  end

  %i[scientific_domains categories].each do |method|
    define_method method do
      object.send(method)&.map { |el| { method.to_s.singularize => el.eid } }
    end
  end

  private

  def camelize_keys_deep(value)
    case value
    when Array
      value.map { |v| camelize_keys_deep(v) }
    when Hash
      value.deep_transform_keys { |k| k.to_s.camelize(:lower) }
    else
      value
    end
  end
end
