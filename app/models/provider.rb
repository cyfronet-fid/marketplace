# frozen_string_literal: true

class Provider < ApplicationRecord
  include Approvable
  include LogoAttachable
  include ImageHelper
  include Publishable
  include Viewable
  include Propagable
  include Statusable
  include Backoffice::ProvidersHelper
  include UrlHelper
  include WizardFormModel

  extend FriendlyId
  friendly_id :pid

  acts_as_taggable

  searchkick word_middle: [:provider_name]

  def search_data
    { provider_id: id, provider_name: name, service_ids: service_ids }
  end

  before_save { self.catalogue = Catalogue.find(catalogue_id) if catalogue_id.present? }

  scope :active, -> { where.not(status: %i[deleted draft]) }
  scope :managed_by, ->(user) { provider_managed_by(user).or(catalogue_managed_by(user)) }
  scope :provider_managed_by,
        ->(user) { includes(:data_administrators).where(data_administrators: { user_id: user&.id }) }
  scope :catalogue_managed_by, ->(user) { where(catalogues: { data_administrators: { user_id: user&.id } }) }

  attr_accessor :catalogue_id

  serialize :participating_countries, coder: Country::Array
  serialize :country, coder: Country

  has_one_attached :logo

  has_many :provider_alternative_identifiers
  has_many :alternative_identifiers, through: :provider_alternative_identifiers

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

  has_one :provider_catalogue, dependent: :destroy
  has_one :catalogue, through: :provider_catalogue

  accepts_nested_attributes_for :link_multimedia_urls, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :alternative_identifiers, allow_destroy: true
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
    self.status ||= :unpublished
  end

  with_options if: -> { required_for_step?("profile") } do
    validates :name, presence: true
    validates :abbreviation, presence: true
    validates :website, presence: true
    validates :description, presence: true
    validates :logo, blob: { content_type: :image }
    validate :valid_urls?, unless: -> { Rails.env.test? }
  end

  with_options if: -> { required_for_step?("location") } do
    validates :street_name_and_number, presence: true
    validates :postal_code, presence: true
    validates :city, presence: true
    validates :country, presence: true
  end

  with_options if: -> { required_for_step?("contacts") } do
    validates :main_contact, presence: true
    validates :public_contacts, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }
  end

  with_options if: -> { required_for_step?("manager") } do
    validates :data_administrators,
              presence: true,
              length: {
                minimum: 1,
                message: "are required. Please add at least one"
              }
  end

  validates :provider_life_cycle_statuses, length: { maximum: 1 }

  validate :logo_variable, on: %i[create update]
  validate :validate_array_values_uniqueness
  validate :catalogue_published

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

  def managed_services
    Service.left_joins(:service_providers).where("status = 'published' AND resource_organisation_id = #{id}")
  end

  def services
    Service.left_joins(:service_providers).where(
      "status = 'published' AND
    (service_providers.provider_id = #{id} OR resource_organisation_id = #{id})"
    )
  end

  def set_default_logo
    assets_path = File.join(File.dirname(__FILE__), "../assets/images")
    default_logo_name = "provider_logo.svg"
    extension = ".svg"
    io = File.open(assets_path + "/" + default_logo_name)

    # This should be fixed by allowing svg extension in the db
    image = convert_to_png(io, extension)
    logo.attach(io: image, filename: SecureRandom.uuid + extension, content_type: "image/#{extension.delete(".", "")}")
  end

  def owned_by?(user)
    data_administrators&.map(&:user_id)&.include?(user&.id) ||
      catalogue&.data_administrators&.map(&:user_id)&.include?(user.id)
  end

  def valid_urls?
    if website_changed? && !UrlHelper.url_valid?(website)
      errors.add(:website, "isn't valid or website doesn't exist, please check URL")
      return false
    end
    true
  end

  def steps(basic: true)
    basic ? basic_steps : extended_steps
  end

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

  def catalogue_published
    errors.add(:catalogue, "must be published") if published? && catalogue.present? && !catalogue.published?
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
