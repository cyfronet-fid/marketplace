# frozen_string_literal: true

class Vocabulary < ApplicationRecord
  include Parentable

  has_many :service_vocabularies, dependent: :destroy
  has_many :services, through: :service_vocabularies
  has_many :catalogue_vocabularies, dependent: :destroy
  has_many :catalogues, through: :catalogue_vocabularies
  has_many :provider_vocabularies, dependent: :destroy
  has_many :providers, through: :provider_vocabularies
  validates :name, presence: true
  validates :type, presence: true

  def to_s
    super
    name
  end
end
