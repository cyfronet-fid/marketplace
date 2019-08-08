# frozen_string_literal: true

class Platform < ApplicationRecord
  has_many :service_related_platforms, dependent: :destroy
  has_many :services, through: :service_related_platforms
  has_many :categorizations, through: :services
  has_many :categories, through: :categorizations

  validates :name, presence: true, uniqueness: true
end
