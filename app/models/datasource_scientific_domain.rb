# frozen_string_literal: true

class DatasourceScientificDomain < ApplicationRecord
  belongs_to :datasource
  belongs_to :scientific_domain

  validates :datasource, presence: true
  validates :scientific_domain, presence: true, uniqueness: { scope: :datasource_id }
end
