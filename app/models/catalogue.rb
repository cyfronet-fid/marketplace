# frozen_string_literal: true

class Catalogue < ApplicationRecord
  extend FriendlyId
  friendly_id :pid

  has_many :service_catalogues, dependent: :destroy
  has_many :services, through: :service_catalogues

  has_many :provider_catalogues, dependent: :destroy
  has_many :providers, through: :provider_catalogues

  has_many :datasource_catalogues, dependent: :destroy
  has_many :datasources, through: :datasource_catalogues
end
