# frozen_string_literal: true

class ServiceRelationship < ApplicationRecord
  belongs_to :source, class_name: "Service", foreign_key: "source_id"
  belongs_to :target, class_name: "Service", foreign_key: "target_id"
end
