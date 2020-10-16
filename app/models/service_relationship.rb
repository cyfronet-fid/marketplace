# frozen_string_literal: true

class ServiceRelationship < ApplicationRecord
  before_create :set_type

  belongs_to :source, class_name: "Service", foreign_key: "source_id"
  belongs_to :target, class_name: "Service", foreign_key: "target_id", foreign_type: :type,
             optional: true, polymorphic: true

  validates :type, presence: true,
            inclusion: %w[ManualServiceRelationship ServiceRelationship RequiredServiceRelationship]

  def set_type
    self.type = type
  end

  def type
    "ServiceRelationship"
  end
end
