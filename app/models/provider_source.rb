# frozen_string_literal: true

class ProviderSource < ApplicationRecord
  enum source_type: { eosc_registry: "eosc_registry" }
  belongs_to :provider, inverse_of: :sources

  validates :eid, presence: true
  validates :source_type, presence: true

  def to_s
    "#{source_type}: #{eid}"
  end
end
