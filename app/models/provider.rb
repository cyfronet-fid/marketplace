# frozen_string_literal: true

class Provider < ApplicationRecord
  has_many :service_providers, dependent: :destroy
  has_many :services, through: :service_providers
  has_many :service_categories, through: :services
  has_many :categories, through: :service_categories

  validates :name, presence: true
end
