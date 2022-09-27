# frozen_string_literal: true

class Vocabulary < ApplicationRecord
  include Parentable

  has_many :service_vocabularies, dependent: :destroy
  has_many :services, through: :service_vocabularies
  has_many :provider_vocabularies, dependent: :destroy
  has_many :providers, through: :provider_vocabularies
  has_many :datasource_vocabularies, dependent: :destroy
  has_many :datasources, through: :datasource_vocabularies
  has_many :persistent_identity_system_vocabularies, dependent: :destroy
  has_many :persistent_identity_systems, through: :persistent_identity_system_vocabularies

  validates :name, presence: true
  validates :type, presence: true

  def to_s
    super()
    name
  end
end
