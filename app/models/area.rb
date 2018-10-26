# frozen_string_literal: true

class Area < ApplicationRecord
  has_many :service_areas, autosave: true, dependent: :destroy
  has_many :services, through: :service_areas
  accepts_nested_attributes_for :services

  validates :name, presence: true
end
