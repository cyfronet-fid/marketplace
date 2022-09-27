# frozen_string_literal: true

class DatasourcePlatform < ApplicationRecord
  belongs_to :datasource
  belongs_to :platform

  validates :datasource, presence: true
  validates :platform, presence: true, uniqueness: { scope: :datasource_id }
end
