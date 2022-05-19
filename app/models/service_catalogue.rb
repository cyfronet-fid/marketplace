# frozen_string_literal: true

class ServiceCatalogue < ApplicationRecord
  belongs_to :service
  belongs_to :catalogue

  validates :service, presence: true, uniqueness: { scope: :service_id }
  validates :catalogue, presence: true
end
