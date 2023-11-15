# frozen_string_literal: true

class ProviderAlternativeIdentifier < ApplicationRecord
  belongs_to :provider
  belongs_to :alternative_identifier

  validates :provider, presence: true
  validates :alternative_identifier, presence: true
end
