# frozen_string_literal: true

class Platform < ApplicationRecord
  has_many :service_related_platforms, dependent: :destroy
  has_many :services, through: :service_related_platforms
  has_many :service_categories, through: :services
  has_many :categories, through: :service_categories

  validates :name, presence: true
end
