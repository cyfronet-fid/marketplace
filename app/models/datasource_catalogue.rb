# frozen_string_literal: true

class DatasourceCatalogue < ApplicationRecord
  belongs_to :datasource
  belongs_to :catalogue

  validates :datasource, presence: true
  validates :catalogue, presence: true, uniqueness: { scope: :datasource_id }
end
