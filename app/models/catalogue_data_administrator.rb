# frozen_string_literal: true

class CatalogueDataAdministrator < ApplicationRecord
  belongs_to :catalogue
  belongs_to :data_administrator

  has_one :user, through: :data_administrator

  validates :catalogue, presence: true
  validates :data_administrator, presence: true
end
