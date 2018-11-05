# frozen_string_literal: true

class Provider < ApplicationRecord
  has_many :services, through: :service_providers
  has_many :service_providers, dependent: :destroy

  validates :name, presence: true
end
