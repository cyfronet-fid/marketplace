# frozen_string_literal: true

class ScientificDomain < ApplicationRecord
  include Parentable
  include LogoAttachable
  include Publishable

  has_one_attached :logo

  has_many :service_scientific_domains, autosave: true, dependent: :destroy
  has_many :services, through: :service_scientific_domains
  has_many :provider_scientific_domains, autosave: true, dependent: :destroy
  has_many :providers, through: :provider_scientific_domains
  has_many :project_scientific_domains, autosave: true, dependent: :destroy
  has_many :projects, through: :project_scientific_domains

  has_many :user_scientific_domains, autosave: true, dependent: :destroy
  has_many :users, through: :user_scientific_domains

  has_many :catalogue_scientific_domains, autosave: true, dependent: :destroy
  has_many :catalogues, through: :catalogue_scientific_domains

  validates :name, presence: true, uniqueness: { scope: :ancestry }
  validates :logo, blob: { content_type: :image }
  validate :logo_variable, on: %i[create update]

  def self.names
    all.map(&:name)
  end

  def to_s
    name
  end
end
