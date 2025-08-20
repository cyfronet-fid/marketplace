# frozen_string_literal: true

class DeployableServiceScientificDomain < ApplicationRecord
  belongs_to :deployable_service
  belongs_to :scientific_domain

  validates :deployable_service_id, uniqueness: { scope: :scientific_domain_id }
end
