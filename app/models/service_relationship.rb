# frozen_string_literal: true

class ServiceRelationship < ApplicationRecord
  before_create :set_type

  belongs_to :source, class_name: "Service", foreign_key: "source_id"
  belongs_to :target,
             class_name: "Service",
             foreign_key: "target_id",
             foreign_type: :type,
             polymorphic: true,
             optional: true

  validates :type,
            presence: true,
            inclusion: %w[ManualServiceRelationship ServiceRelationship RequiredServiceRelationship]

  def set_type
    self.type = type
  end
end
