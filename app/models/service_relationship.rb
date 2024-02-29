# frozen_string_literal: true

class ServiceRelationship < ApplicationRecord
  belongs_to :source, class_name: "Service", foreign_key: "source_id"
  belongs_to :target,
             class_name: "Service",
             foreign_key: "target_id",
             foreign_type: :type,
             optional: true,
             polymorphic: true

  validates :type,
            presence: true,
            inclusion: %w[ManualServiceRelationship ServiceRelationship RequiredServiceRelationship]
end
