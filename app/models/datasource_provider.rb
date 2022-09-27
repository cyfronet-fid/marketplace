# frozen_string_literal: true

class DatasourceProvider < ApplicationRecord
  belongs_to :provider
  belongs_to :datasource

  validates :provider, presence: true, uniqueness: { scope: :datasource_id }
  validates :datasource, presence: true
end
