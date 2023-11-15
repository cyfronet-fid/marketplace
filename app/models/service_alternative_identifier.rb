# frozen_string_literal: true

class ServiceAlternativeIdentifier < ApplicationRecord
  belongs_to :service
  belongs_to :alternative_identifier

  validates :service, presence: true
  validates :alternative_identifier, presence: true
end
