# frozen_string_literal: true

class Service < ApplicationRecord
  include Service::Search
  include LogoAttachable

  extend FriendlyId
  friendly_id :name, use: :slugged

  acts_as_taggable

  before_save :remove_empty_array_fields

  has_one_attached :logo

  enum order_type: {
         open_access: "open_access",
         fully_open_access: "fully_open_access",
         order_required: "order_required",
         other: "other"
       }

  enum phase: {
         discovery: "discovery",
         planned: "planned",
         alpha: "alpha",
         beta: "beta",
         production: "production",
         retired: "retired"
       }

  STATUSES = {
    published: "published",
    unverified: "unverified",
    draft: "draft",
    errored: "errored",
    deleted: "deleted"
  }.freeze

  enum status: STATUSES

  has_many :offers, dependent: :restrict_with_error
  has_many :project_items, through: :offers
  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :service_opinions, through: :project_items
  has_many :service_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :service_scientific_domains
  has_many :service_providers, dependent: :destroy
  has_many :providers, through: :service_providers
  has_many :service_related_platforms, dependent: :destroy
  has_many :platforms, through: :service_related_platforms
  has_many :service_vocabularies, dependent: :destroy
  has_many :funding_bodies, through: :service_vocabularies, source: :vocabulary, source_type: "Vocabulary::FundingBody"
  has_many :funding_programs,
           through: :service_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::FundingProgram"
  has_many :access_modes, through: :service_vocabularies, source: :vocabulary, source_type: "Vocabulary::AccessMode"
  has_many :access_types, through: :service_vocabularies, source: :vocabulary, source_type: "Vocabulary::AccessType"
  has_many :trl, through: :service_vocabularies, source: :vocabulary, source_type: "Vocabulary::Trl"
  has_many :life_cycle_status,
           through: :service_vocabularies,
           source: :vocabulary,
           source_type: "Vocabulary::LifeCycleStatus"
  has_many :service_target_users, dependent: :destroy
  has_many :target_users, through: :service_target_users
  has_many :omses, dependent: :destroy

  has_one :main_contact, as: :contactable, dependent: :destroy, autosave: true
  has_many :public_contacts, as: :contactable, dependent: :destroy, autosave: true

  accepts_nested_attributes_for :main_contact,
                                reject_if: lambda { |attributes| attributes["email"].blank? },
                                allow_destroy: true

  accepts_nested_attributes_for :public_contacts,
                                reject_if: lambda { |attributes| attributes["email"].blank? },
                                allow_destroy: true

  has_many :user_services, dependent: :destroy
  has_many :favourite_users, through: :user_services, source: :user, class_name: "User"

  has_many :service_user_relationships, dependent: :destroy
  has_many :owners, through: :service_user_relationships, source: :user, class_name: "User"

  has_many :source_relationships,
           class_name: "ServiceRelationship",
           foreign_key: "target_id",
           dependent: :destroy,
           inverse_of: :target

  has_many :target_relationships,
           class_name: "ServiceRelationship",
           foreign_key: "source_id",
           dependent: :destroy,
           inverse_of: :source

  has_many :related_services,
           through: :target_relationships,
           class_name: "Service",
           source: :target,
           source_type: "ServiceRelationship"

  has_many :manual_related_services,
           through: :target_relationships,
           class_name: "Service",
           source: :target,
           source_type: "ManualServiceRelationship"

  has_many :required_services,
           through: :target_relationships,
           class_name: "Service",
           source: :target,
           source_type: "RequiredServiceRelationship"

  has_many :sources, class_name: "ServiceSource", dependent: :destroy

  accepts_nested_attributes_for :sources,
                                reject_if:
                                  lambda { |attributes| attributes["eid"].blank? || attributes["source_type"].blank? },
                                allow_destroy: true

  belongs_to :upstream, foreign_key: "upstream_id", class_name: "ServiceSource", optional: true
  belongs_to :resource_organisation, class_name: "Provider", optional: false

  serialize :geographical_availabilities, Country::Array
  serialize :resource_geographic_locations, Country::Array

  validates :name, presence: true
  validates :description, presence: true
  validates :tagline, presence: true
  validates :rating, presence: true
  validates :multimedia, array: { mp_url: true }
  validates :terms_of_use_url, mp_url: true, if: :terms_of_use_url?
  validates :access_policies_url, mp_url: true, if: :access_policies_url?
  validates :sla_url, mp_url: true, if: :sla_url?
  validates :webpage_url, mp_url: true, if: :webpage_url?
  validates :status_monitoring_url, mp_url: true, if: :status_monitoring_url?
  validates :maintenance_url, mp_url: true, if: :maintenance_url?
  validates :order_url, mp_url: true, if: :order_url?
  validates :payment_model_url, mp_url: true, if: :payment_model_url?
  validates :pricing_url, mp_url: true, if: :pricing_url?
  validates :manual_url, mp_url: true, if: :manual_url?
  validates :helpdesk_url, mp_url: true, if: :helpdesk_url?
  validates :helpdesk_email, allow_blank: true, email: true
  validates :security_contact_email, allow_blank: true, email: true
  validates :use_cases_url, array: { mp_url: true }
  validates :privacy_policy_url, mp_url: true, if: :privacy_policy_url?
  validates :training_information_url, mp_url: true, if: :training_information_url?
  validates :language_availability, array: true
  validates :logo, blob: { content_type: :image }
  validate :logo_variable, on: %i[create update]
  validates :scientific_domains, presence: true
  validates :status, presence: true
  validates :trl, length: { maximum: 1 }
  validates :life_cycle_status, length: { maximum: 1 }
  validates :geographical_availabilities, presence: true
  validates :resource_organisation, presence: true

  after_save :set_first_category_as_main!, if: :main_category_missing?

  def self.popular(count)
    where(status: %i[published unverified]).includes(:providers).order(popularity_ratio: :desc, name: :asc).limit(count)
  end

  def main_category
    @main_category ||= categories.joins(:categorizations).find_by(categorizations: { main: true })
  end

  def set_first_category_as_main!
    categorizations.first&.update(main: true)
  end

  def offers?
    offers_count.positive?
  end

  def languages
    language_availability.map { |l| I18nData.languages[l.upcase] || l }
  end

  def aod?
    platforms.pluck(:name).include?("EGI Applications on Demand")
  end

  def owned_by?(user)
    service_user_relationships.where(user: user).count.positive?
  end

  def administered_by?(user)
    resource_organisation.administered_by?(user)
  end

  def geographical_availabilities=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def resource_geographic_locations=(value)
    super(value&.map { |v| Country.for(v) })
  end

  def target_relationships
    (required_services + manual_related_services + related_services).uniq
  end

  def resource_organisation_and_providers
    ([resource_organisation] + Array(providers)).reject(&:blank?).uniq
  end

  def resource_organisation_name
    resource_organisation.name
  end

  def external?
    order_required? && order_url.present?
  end

  def providers?
    providers.reject(&:blank?).reject { |p| p == resource_organisation }.size.positive?
  end

  def available_omses
    (OMS.where(default: true).to_a + omses.to_a + OMS.where(type: :global).to_a + resource_organisation&.omses).uniq
  end

  private

  def remove_empty_array_fields
    array_fields = %i[
      multimedia
      use_cases_url
      certifications
      standards
      open_source_technologies
      changelog
      related_platforms
      grant_project_names
    ]
    array_fields.each do |field|
      send(field).present? ? send(:"#{field}=", send(field).reject(&:blank?)) : send(:"#{field}=", [])
    end
  end

  def main_category_missing?
    categorizations.where(main: true).count.zero?
  end
end
