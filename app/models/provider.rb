# frozen_string_literal: true

class Provider < ApplicationRecord
  include LogoAttachable
  include ImageHelper
  include Publishable

  extend FriendlyId
  friendly_id :pid

  acts_as_taggable

  searchkick word_middle: [:provider_name]

  STATUSES = { published: "published", deleted: "deleted", draft: "draft" }.freeze

  enum status: STATUSES

  def search_data
    { provider_id: id, provider_name: name, service_ids: service_ids }
  end

  before_save { self.catalogue = Catalogue.find(catalogue_id) if catalogue_id.present? }

  scope :active, -> { where.not(status: %i[deleted draft]) }

  attr_accessor :catalogue_id

  has_one_attached :logo

  serialize :participating_countries, Country::Array
  serialize :country, Country

  has_many :service_providers, dependent: :destroy
  has_many :services, through: :service_providers
  has_many :link_multimedia_urls, as: :linkable, dependent: :destroy, autosave: true, class_name: "Link::MultimediaUrl"
  has_many :categorizations, through: :services
  has_many :bundles, foreign_key: "resource_organisation_id"
  has_many :categories, through: :categorizations
  has_many :provider_data_administrators
  has_many :provider_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :provider_scientific_domains
  has_many :data_administrators, through: :provider_data_administrators, dependent: :destroy, autosave: true
  has_many :provider_vocabularies, dependent: :destroy
  has_many :hosting_legal_entities,
           through: :provider_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::HostingLegalEntity"
  has_many :legal_statuses, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::LegalStatus"
  has_many :provider_life_cycle_statuses,
           through: :provider_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::ProviderLifeCycleStatus"
  has_many :networks, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::Network"
  has_many :structure_types,
           through: :provider_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::StructureType"
  has_many :esfri_domains, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::EsfriDomain"
  has_many :esfri_types, through: :provider_vocabularies, source: :vocabulary, source_type: "Vocabulary::EsfriType"
  has_many :meril_scientific_domains,
           through: :provider_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::MerilScientificDomain"
  has_many :areas_of_activity,
           through: :provider_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::AreaOfActivity"
  has_many :societal_grand_challenges,
           through: :provider_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::SocietalGrandChallenge"
  has_many :oms_providers, dependent: :destroy
  has_many :omses, through: :oms_providers

  has_one :main_contact, as: :contactable, dependent: :destroy, autosave: true
  has_many :public_contacts, as: :contactable, dependent: :destroy, autosave: true

  has_many :sources, class_name: "ProviderSource", dependent: :destroy

  belongs_to :upstream, foreign_key: "upstream_id", class_name: "ProviderSource", optional: true

  accepts_nested_attributes_for :link_multimedia_urls, reject_if: :all_blank, allow_destroy: true

  has_one :provider_catalogue, dependent: :destroy
  has_one :catalogue, through: :provider_catalogue

  accepts_nested_attributes_for :main_contact, allow_destroy: true

  accepts_nested_attributes_for :public_contacts, allow_destroy: true

  accepts_nested_attributes_for :sources, allow_destroy: true

  accepts_nested_attributes_for :data_administrators, allow_destroy: true

  auto_strip_attributes :name, nullify: false
  auto_strip_attributes :pid, nullify: false
  auto_strip_attributes :abbreviation, nullify: false
  auto_strip_attributes :website, nullify: false
  auto_strip_attributes :description, nullify: false
  auto_strip_attributes :street_name_and_number, nullify: false
  auto_strip_attributes :postal_code, nullify: false
  auto_strip_attributes :city, nullify: false
  auto_strip_attributes :region, nullify: false
  auto_strip_attributes :hosting_legal_entity_string, nullify: false
  auto_strip_attributes :status, nullify: false
  auto_strip_attributes :certifications, nullify_array: false
  auto_strip_attributes :affiliations, nullify_array: false
  auto_strip_attributes :national_roadmaps, nullify_array: false
  auto_strip_attributes :tag_list, nullify_array: false

  before_validation do
    remove_empty_array_fields
    self.legal_status = nil unless legal_entity
    self.status ||= :published
  end

  validates :name, presence: true
  validates :abbreviation, presence: true
  validates :website, presence: true
  validates :description, presence: true
  validates :street_name_and_number, presence: true
  validates :postal_code, presence: true
  validates :city, presence: true
  validates :country, presence: true
  validates :logo, presence: true, blob: { content_type: :image }
  validates :provider_life_cycle_statuses, length: { maximum: 1 }
  validates :public_contacts, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }
  validates :data_administrators,
            presence: true,
            length: {
              minimum: 1,
              message: "are required. Please add at least one"
            }
  validates :status, presence: true
  validate :logo_variable, on: %i[create update]
  validate :validate_array_values_uniqueness

  def legal_status=(status_id)
    self.legal_statuses = status_id.blank? ? [] : [Vocabulary.find(status_id)]
  end

  def legal_status
    return nil if legal_statuses.blank?

    legal_statuses[0].id
  end

  def hosting_legal_entity=(entity_id)
    self.hosting_legal_entities = entity_id.blank? ? [] : [Vocabulary.find(entity_id)]
  end

  def hosting_legal_entity
    return nil if hosting_legal_entities.blank?

    hosting_legal_entities[0].id
  end

  def esfri_type=(type_id)
    self.esfri_types = type_id.blank? ? [] : [Vocabulary.find(type_id)]
  end

  def esfri_type
    return nil if esfri_types.blank?

    esfri_types[0].id
  end

  def provider_life_cycle_status=(status_id)
    self.provider_life_cycle_statuses = status_id.blank? ? [] : [Vocabulary.find(status_id)]
  end

  def provider_life_cycle_status
    return nil if provider_life_cycle_statuses.blank?

    provider_life_cycle_statuses[0].id
  end

  def participating_countries=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def country=(value)
    super(Country.for(value))
  end

  def postal_code_and_city
    "#{postal_code} #{city}"
  end

  def address
    "#{street_name_and_number} <br> #{postal_code} #{city} <br> #{region} #{country}"
  end

  def services
    Service
      .left_joins(:service_providers)
      .where(
        "(status = 'unverified' OR status = 'published') AND
    (service_providers.provider_id = #{id} OR resource_organisation_id = #{id})"
      )
  end

  def set_default_logo
    assets_path = File.join(File.dirname(__FILE__), "../javascript/images")
    default_logo_name = "eosc-img.png"
    extension = ".png"
    io = ImageHelper.binary_to_blob_stream(assets_path + "/" + default_logo_name)
    logo.attach(io: io, filename: SecureRandom.uuid + extension, content_type: "image/#{extension.delete(".", "")}")
  end

  def administered_by?(user)
    data_administrators.where(email: user.email).count.positive?
  end

  private

  def remove_empty_array_fields
    send(
      :data_administrators=,
      data_administrators.reject do |administrator|
        administrator.attributes["created_at"].blank? && administrator.attributes.all? { |_, value| value.blank? }
      end
    )
    send(
      :public_contacts=,
      public_contacts.reject do |contact|
        contact.attributes["created_at"].blank? &&
          contact.attributes.except("contactable_type", "type", "contactable_id").all? { |_, value| value.blank? }
      end
    )
  end

  def validate_array_values_uniqueness
    errors.add(:tag_list, "has duplicates, please remove them to continue") if tag_list.uniq.length != tag_list.length
    if certifications.uniq.length != certifications.length
      errors.add(:certifications, "has duplicates, please remove them to continue")
    end
    if national_roadmaps.uniq.length != national_roadmaps.length
      errors.add(:national_roadmaps, "has duplicates, please remove them to continue")
    end
  end

  def logo_changed?
    return false if Provider.where(id: id).blank?

    has_new_logo = logo.attached? && logo.variable?
    previous_logo = Provider.find(id).logo
    has_previous_logo = previous_logo.attached? && previous_logo.variable?

    return false if !has_previous_logo && !has_new_logo

    return true if (has_new_logo && !has_previous_logo) || (!has_new_logo && has_previous_logo)

    logo.attachment.blob != previous_logo.attachment.blob
  end
end
