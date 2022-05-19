# frozen_string_literal: true

class ProviderCatalogue < ApplicationRecord
  belongs_to :provider
  belongs_to :catalogue

  validates :provider, presence: true, uniqueness: { scope: :provider_id }
  validates :catalogue, presence: true
end
