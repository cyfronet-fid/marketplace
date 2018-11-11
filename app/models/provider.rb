# frozen_string_literal: true

class Provider < ApplicationRecord
  has_many :service_providers, dependent: :destroy
  has_many :services, through: :service_providers

  validates :name, presence: true
end
