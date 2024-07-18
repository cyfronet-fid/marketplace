# frozen_string_literal: true

class Catalogue < ApplicationRecord
  extend FriendlyId
  include LogoAttachable
  include Propagable
  include Statusable

  friendly_id :pid

  acts_as_taggable

  has_one_attached :logo

  serialize :participating_countries, coder: Country::Array
  serialize :country, coder: Country

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

  has_many :sources, class_name: "CatalogueSource", dependent: :destroy
  belongs_to :upstream, foreign_key: "upstream_id", class_name: "CatalogueSource", optional: true

  has_many :catalogue_data_administrators
  has_many :data_administrators, through: :catalogue_data_administrators, dependent: :destroy, autosave: true

  scope :managed_by, ->(user) { joins(:data_administrators).where(data_administrators: { user_id: user&.id }) }

  accepts_nested_attributes_for :data_administrators, allow_destroy: true
  accepts_nested_attributes_for :main_contact, allow_destroy: true
  accepts_nested_attributes_for :public_contacts, allow_destroy: true
  accepts_nested_attributes_for :link_multimedia_urls, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :sources, allow_destroy: true

  validates :name, presence: true
  validates :abbreviation, presence: true
  validates :website, presence: true
  validates :inclusion_criteria, presence: true
  validates :end_of_life, presence: true
  validates :validation_process, presence: true
  validates :scope, presence: true
  validates :description, presence: true
  validates :street_name_and_number, presence: true
  validates :postal_code, presence: true
  validates :city, presence: true
  validates :country, presence: true
  validates :public_contacts, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }
  validate :logo_variable, on: %i[create update]
  validates :data_administrators,
            presence: true,
            length: {
              minimum: 1,
              message: "are required. Please add at least one"
            }

  def participating_countries=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def country=(value)
    super(Country.for(value))
  end

  def affiliations=(value)
    super(value.compact_blank)
  end

  def hosting_legal_entity
    return nil if hosting_legal_entities.blank?

    hosting_legal_entities[0].id
  end

  def hosting_legal_entity=(entity_id)
    self.hosting_legal_entities = entity_id.blank? ? [] : [Vocabulary.find(entity_id)]
  end

  def legal_status
    return nil if legal_statuses.blank?

    legal_statuses[0].id
  end

  def owned_by?(user)
    data_administrators.map(&:user_id).include?(user.id)
  end

  def legal_status=(status_id)
    self.legal_statuses = status_id.blank? ? [] : [Vocabulary.find(status_id)]
  end
end
