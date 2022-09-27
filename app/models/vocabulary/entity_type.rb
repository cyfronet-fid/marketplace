# frozen_string_literal: true

class Vocabulary::EntityType < Vocabulary
  has_many :persistent_identity_systems, foreign_key: "entity_type_id", inverse_of: "entity_type"
end
