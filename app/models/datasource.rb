# frozen_string_literal: true

class Datasource < ApplicationRecord
  include Datasource::Search
  include LogoAttachable
  include Presentable

  extend FriendlyId
  friendly_id :pid

  acts_as_taggable

  has_one_attached :logo

  PUBLIC_STATUSES = %w[published unverified errored].freeze

  STATUSES = {
    published: "published",
    unverified: "unverified",
    draft: "draft",
    errored: "errored",
    deleted: "deleted"
  }.freeze

  enum status: STATUSES

  scope :visible, -> { where(status: %i[published unverified]) }
  scope :horizontal, -> { where(horizontal: true) }

  before_save do
    self.pid = sources&.first&.eid || abbreviation if pid.blank?
    self.persistent_identity_systems =
      persistent_identity_systems.reject { |p| p.entity_type.blank? && p.entity_type_schemes.blank? }
  end

  enum order_types: {
         open_access: "open_access",
         fully_open_access: "fully_open_access",
         order_required: "order_required",
         other: "other"
       }.freeze

  serialize :geographical_availabilities, Country::Array
  serialize :geographic_locations, Country::Array

  belongs_to :resource_organisation, class_name: "Provider", optional: false
  has_many :datasource_providers, dependent: :destroy
  has_many :providers, through: :datasource_providers, validate: false
  has_many :link_use_cases_urls, as: :linkable, dependent: :destroy, autosave: true, class_name: "Link::UseCasesUrl"
  has_many :link_multimedia_urls, as: :linkable, dependent: :destroy, autosave: true, class_name: "Link::MultimediaUrl"
  has_many :link_research_product_license_urls,
           as: :linkable,
           dependent: :destroy,
           autosave: true,
           class_name: "Link::ResearchProductLicenseUrl"
  has_many :link_research_product_metadata_license_urls,
           as: :linkable,
           dependent: :destroy,
           autosave: true,
           class_name: "Link::ResearchProductMetadataLicenseUrl"
  has_many :datasource_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :datasource_scientific_domains, validate: false
  has_many :datasource_categories, dependent: :destroy
  has_many :categories, through: :datasource_categories, validate: false
  has_many :datasource_target_users, dependent: :destroy
  has_many :target_users, through: :datasource_target_users, validate: false
  has_one :main_contact, as: :contactable, dependent: :destroy, autosave: true
  has_many :public_contacts, as: :contactable, dependent: :destroy, autosave: true
  has_many :datasource_vocabularies, dependent: :destroy
  has_many :research_steps,
           through: :datasource_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::ResearchStep"
  has_many :access_types, through: :datasource_vocabularies, source: :vocabulary, source_type: "Vocabulary::AccessType"
  has_many :access_modes, through: :datasource_vocabularies, source: :vocabulary, source_type: "Vocabulary::AccessMode"
  has_many :trl, through: :datasource_vocabularies, source: :vocabulary, source_type: "Vocabulary::Trl"
  has_many :life_cycle_status,
           through: :datasource_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::LifeCycleStatus"
  has_many :datasource_services, dependent: :destroy

  has_many :required_services,
           through: :datasource_services,
           class_name: "Service",
           source: :service,
           source_type: "RequiredService"

  has_many :related_services,
           through: :datasource_services,
           class_name: "Service",
           source: :service,
           source_type: "RelatedService"

  has_many :datasource_platforms, dependent: :destroy
  has_many :platforms, through: :datasource_platforms
  has_many :datasource_catalogues, dependent: :destroy
  has_many :catalogues, through: :datasource_catalogues
  has_many :funding_bodies,
           through: :datasource_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::FundingBody"
  has_many :funding_programs,
           through: :datasource_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::FundingProgram"
  has_many :persistent_identity_systems,
           class_name: "PersistentIdentitySystem",
           autosave: true,
           dependent: :destroy,
           inverse_of: :datasource
  belongs_to :jurisdiction, class_name: "Vocabulary::Jurisdiction", optional: true
  belongs_to :datasource_classification, class_name: "Vocabulary::DatasourceClassification", optional: true
  has_many :research_entity_types,
           through: :datasource_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::EntityType"
  has_many :research_product_access_policies,
           through: :datasource_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::ResearchProductAccessPolicy"
  has_many :research_product_metadata_access_policies,
           through: :datasource_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::ResearchProductMetadataAccessPolicy"

  has_many :sources, class_name: "DatasourceSource", dependent: :destroy
  belongs_to :upstream, foreign_key: "upstream_id", class_name: "DatasourceSource", optional: true

  accepts_nested_attributes_for :sources,
                                reject_if:
                                  lambda { |attributes| attributes["eid"].blank? || attributes["source_type"].blank? },
                                allow_destroy: true

  accepts_nested_attributes_for :main_contact, allow_destroy: true
  accepts_nested_attributes_for :public_contacts, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :link_multimedia_urls, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :link_use_cases_urls, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :persistent_identity_systems,
                                reject_if:
                                  lambda { |attributes|
                                    attributes["entity_type_id"].blank? && attributes["entity_type_scheme_ids"].blank?
                                  },
                                allow_destroy: true
  accepts_nested_attributes_for :link_research_product_license_urls, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :link_research_product_metadata_license_urls, reject_if: :all_blank, allow_destroy: true

  auto_strip_attributes :name, nullify: false
  auto_strip_attributes :description, nullify: false
  auto_strip_attributes :tagline, nullify: false
  auto_strip_attributes :terms_of_use_url, nullify: false
  auto_strip_attributes :resource_level_url, nullify: false
  auto_strip_attributes :webpage_url, nullify: false
  auto_strip_attributes :user_manual_url, nullify: false
  auto_strip_attributes :helpdesk_url, nullify: false
  auto_strip_attributes :training_information_url, nullify: false
  auto_strip_attributes :helpdesk_email, nullify: false
  auto_strip_attributes :status_monitoring_url, nullify: false
  auto_strip_attributes :maintenance_url, nullify: false
  auto_strip_attributes :order_url, nullify: false
  auto_strip_attributes :payment_model_url, nullify: false
  auto_strip_attributes :pricing_url, nullify: false
  auto_strip_attributes :security_contact_email, nullify: false
  auto_strip_attributes :privacy_policy_url, nullify: false
  auto_strip_attributes :language_availability, nullify_array: false
  auto_strip_attributes :certifications, nullify_array: false
  auto_strip_attributes :standards, nullify_array: false
  auto_strip_attributes :open_source_technologies, nullify_array: false
  auto_strip_attributes :changelog, nullify_array: false
  auto_strip_attributes :grant_project_names, nullify_array: false

  validates :name, presence: true
  validates :description, presence: true
  validates :tagline, presence: true
  validates :webpage_url, presence: true, mp_url: true

  validates :helpdesk_email, allow_blank: true, email: true
  validates :security_contact_email, allow_blank: true, email: true

  validates :helpdesk_url, mp_url: true, if: :helpdesk_url?
  validates :user_manual_url, mp_url: true, if: :user_manual_url?
  validates :terms_of_use_url, mp_url: true, if: :terms_of_use_url?
  validates :privacy_policy_url, mp_url: true, if: :privacy_policy_url?
  validates :access_policy_url, mp_url: true, if: :access_policy_url?
  validates :resource_level_url, mp_url: true, if: :resource_level_url?
  validates :training_information_url, mp_url: true, if: :training_information_url?
  validates :status_monitoring_url, mp_url: true, if: :status_monitoring_url?
  validates :maintenance_url, mp_url: true, if: :maintenance_url?

  validates :order_type, presence: true
  validates :order_url, mp_url: true, if: :order_url?
  validates :payment_model_url, mp_url: true, if: :payment_model_url?
  validates :pricing_url, mp_url: true, if: :pricing_url?

  validates :geographical_availabilities,
            presence: true,
            length: {
              minimum: 1,
              message: "are required. Please add at least one"
            }
  validates :language_availability, array: true
  validates :logo, blob: { content_type: :image }
  validate :logo_variable, on: %i[create update]
  validates :scientific_domains,
            presence: true,
            length: {
              minimum: 1,
              message: "are required. Please add at least one"
            }
  validates :status, presence: true
  validates :trl, length: { maximum: 1 }
  validates :life_cycle_status, length: { maximum: 1 }

  validates :resource_organisation, presence: true
  validates :public_contacts, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }

  after_save :set_first_category_as_main!, if: :main_category_missing?

  def languages
    language_availability.map { |l| I18nData.languages[l.upcase] || l }
  end

  def geographical_availabilities=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def geographic_locations=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def administered_by?(user)
    resource_organisation&.administered_by?(user) || false
  end

  def catalogue
    catalogues.first
  end

  def set_first_category_as_main!
    datasource_categories.first&.update(main: true)
  end

  private

  def main_category_missing?
    datasource_categories.where(main: true).count.zero?
  end
end
