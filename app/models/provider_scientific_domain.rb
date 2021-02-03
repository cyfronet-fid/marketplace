# frozen_string_literal: true

class ProviderScientificDomain < ApplicationRecord
  belongs_to :provider
  belongs_to :scientific_domain

  validates :provider, presence: true
  validates :scientific_domain, presence: true, uniqueness: { scope: :provider_id }
end
