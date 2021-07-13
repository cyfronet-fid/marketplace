# frozen_string_literal: true

class ServiceSource < ApplicationRecord
  enum source_type: { eosc_registry: "eosc_registry" }
  belongs_to :service, inverse_of: :sources

  validates :eid, presence: true
  validates :source_type, presence: true

  def to_s
    "#{source_type}: #{eid}"
  end
end
