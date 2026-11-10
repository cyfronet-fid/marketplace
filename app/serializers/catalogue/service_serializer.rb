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
      object.send(method)&.map(&:eid)&.compact_blank
    end
  end

  # The catalogue schema expects the vocabulary id (trl-9), not the label
  def trls
    object.trls.first&.eid.presence
  end

  # The catalogue schema expects {domain, subdomain} pairs, while services are linked to tree nodes
  def scientific_domains
    classification_pairs(object.scientific_domains, parent_depth: 0, keys: %i[scientific_domain scientific_subdomain])
  end

  # Category tree is supercategory > category > subcategory; the schema expects {category, subcategory} pairs
  def categories
    classification_pairs(object.categories, parent_depth: 1, keys: %i[category subcategory])
  end

  private

  # Nodes above parent_depth (supercategories) have no place in the schema and are dropped.
  # A parent-level node is emitted alone only when none of its children is linked.
  # Nodes without an EOSC id (created locally in the backoffice) cannot be published.
  def classification_pairs(nodes, parent_depth:, keys:)
    parent_key, child_key = keys
    nodes = nodes.to_a.select { |node| node.eid.present? }
    return [] if nodes.empty?

    children = nodes.select { |node| node.depth > parent_depth }
    parents = nodes.first.class.where(id: children.map(&:parent_id)).index_by(&:id)

    pairs =
      children.filter_map do |node|
        parent_eid = parents[node.parent_id]&.eid
        { parent_key => parent_eid, child_key => node.eid } if parent_eid.present?
      end
    lone_parents = nodes.select { |node| node.depth == parent_depth && parents.exclude?(node.id) }

    (pairs + lone_parents.map { |node| { parent_key => node.eid } }).uniq
  end

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
