# frozen_string_literal: true

class PersistentIdentitySystem < ApplicationRecord
  belongs_to :datasource, foreign_key: "service_id", inverse_of: :persistent_identity_systems, class_name: "Service"

  belongs_to :entity_type, class_name: "Vocabulary::EntityType", optional: true
  has_many :persistent_identity_system_vocabularies, dependent: :destroy
  has_many :entity_type_schemes,
           through: :persistent_identity_system_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::EntityTypeScheme"

  # validates :entity_type_id, presence: true
  # validates :entity_type_schemes, presence: true, array: true, if: :entity_type_id?

  def entity_type_scheme_names
    entity_type_schemes.map(&:name).join(", ")
  end
end
