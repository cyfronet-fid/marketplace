# frozen_string_literal: true

class AlternativeIdentifier < ApplicationRecord
  has_many :service_alternative_identifiers
  has_many :services, through: :service_alternative_identifiers

  has_many :provider_alternative_identifiers
  has_many :providers, through: :provider_alternative_identifiers
end
