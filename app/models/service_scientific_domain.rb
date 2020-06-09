# frozen_string_literal: true

class ServiceScientificDomain < ApplicationRecord
  belongs_to :service
  belongs_to :scientific_domain

  validates :service, presence: true
  validates :scientific_domain, presence: true, uniqueness: { scope: :service_id }
end
