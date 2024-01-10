# frozen_string_literal: true

class Catalogue < ApplicationRecord
  extend FriendlyId
  include LogoAttachable

  STATUSES = { published: "published", deleted: "deleted", draft: "draft" }.freeze
  enum status: STATUSES

  friendly_id :pid

  has_one_attached :logo

  serialize :participating_countries, Country::Array
  serialize :country, Country

  has_many :service_catalogues, dependent: :destroy
  has_many :services, through: :service_catalogues

  has_many :provider_catalogues, dependent: :destroy
  has_many :providers, through: :provider_catalogues

  has_many :datasource_catalogues, dependent: :destroy
  has_many :datasources, through: :datasource_catalogues

  has_many :catalogue_scientific_domains, autosave: true, dependent: :destroy
  has_many :scientific_domains, through: :catalogue_scientific_domains

  has_one :main_contact, as: :contactable, dependent: :destroy, autosave: true
  has_many :public_contacts, as: :contactable, dependent: :destroy, autosave: true

  has_many :link_multimedia_urls, as: :linkable, dependent: :destroy, autosave: true, class_name: "Link::MultimediaUrl"

  # Vocabularies
  has_many :catalogue_vocabularies, dependent: :destroy
  has_many :networks, through: :catalogue_vocabularies, source: :vocabulary, source_type: "Vocabulary::Network"
  has_many :legal_statuses,
           through: :catalogue_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::LegalStatus"
  has_many :hosting_legal_entities,
           through: :catalogue_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::HostingLegalEntity"

  scope :active, -> { where.not(status: %i[deleted draft]) }

  accepts_nested_attributes_for :main_contact, allow_destroy: true
  accepts_nested_attributes_for :public_contacts, allow_destroy: true
  accepts_nested_attributes_for :link_multimedia_urls, reject_if: :all_blank, allow_destroy: true

  def participating_countries=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def country=(value)
    super(Country.for(value))
  end
end
