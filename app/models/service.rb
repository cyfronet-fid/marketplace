# frozen_string_literal: true

class Service < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Service::Search
  include LogoAttachable
  include Publishable
  include Presentable

  extend FriendlyId
  friendly_id :name, use: :slugged

  acts_as_taggable

  before_save { self.catalogue = Catalogue.find(catalogue_id) if catalogue_id.present? }

  attr_accessor :analytics, :catalogue_id, :monitoring_status, :bundle_id

  PUBLIC_STATUSES = %w[published unverified errored].freeze

  scope :horizontal, -> { where(horizontal: true) }

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
  has_many :bundles, dependent: :restrict_with_error
  has_many :project_items, through: :offers
  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :service_opinions, through: :project_items
  has_many :service_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :service_scientific_domains
  has_many :service_providers, dependent: :destroy
  has_many :providers, through: :service_providers, validate: false
  has_many :service_related_platforms, dependent: :destroy
  has_many :platforms, through: :service_related_platforms
  has_many :link_use_cases_urls, as: :linkable, dependent: :destroy, autosave: true, class_name: "Link::UseCasesUrl"
  has_many :link_multimedia_urls, as: :linkable, dependent: :destroy, autosave: true, class_name: "Link::MultimediaUrl"
  has_many :service_vocabularies, dependent: :destroy
  has_many :research_steps, through: :service_vocabularies, source: :vocabulary, source_type: "Vocabulary::ResearchStep"
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

  accepts_nested_attributes_for :main_contact, allow_destroy: true
  accepts_nested_attributes_for :public_contacts, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :link_multimedia_urls, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :link_use_cases_urls, reject_if: :all_blank, allow_destroy: true

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

  has_many :service_guidelines
  has_many :guidelines, through: :service_guidelines

  accepts_nested_attributes_for :sources,
                                reject_if:
                                  lambda { |attributes| attributes["eid"].blank? || attributes["source_type"].blank? },
                                allow_destroy: true

  belongs_to :upstream, foreign_key: "upstream_id", class_name: "ServiceSource", optional: true
  belongs_to :resource_organisation, class_name: "Provider", optional: false

  has_one :service_catalogue, dependent: :destroy
  has_one :catalogue, through: :service_catalogue

  serialize :geographical_availabilities, Country::Array
  serialize :resource_geographic_locations, Country::Array

  auto_strip_attributes :name, nullify: false
  auto_strip_attributes :description, nullify: false
  auto_strip_attributes :tagline, nullify: false
  auto_strip_attributes :terms_of_use_url, nullify: false
  auto_strip_attributes :access_policies_url, nullify: false
  auto_strip_attributes :sla_url, nullify: false
  auto_strip_attributes :webpage_url, nullify: false
  auto_strip_attributes :manual_url, nullify: false
  auto_strip_attributes :helpdesk_url, nullify: false
  auto_strip_attributes :training_information_url, nullify: false
  auto_strip_attributes :restrictions, nullify: false
  auto_strip_attributes :activate_message, nullify: false
  auto_strip_attributes :slug, nullify: false
  auto_strip_attributes :order_type, nullify: false
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
  auto_strip_attributes :related_platforms, nullify_array: false
  auto_strip_attributes :grant_project_names, nullify_array: false

  validates :name, presence: true
  validates :description, presence: true
  validates :tagline, presence: true
  validates :rating, presence: true
  validates :terms_of_use_url, mp_url: true, if: :terms_of_use_url?
  validates :access_policies_url, mp_url: true, if: :access_policies_url?
  validates :sla_url, mp_url: true, if: :sla_url?
  validates :webpage_url, mp_url: true, if: :webpage_url?
  validates :order_type, presence: true
  validates :status_monitoring_url, mp_url: true, if: :status_monitoring_url?
  validates :maintenance_url, mp_url: true, if: :maintenance_url?
  validates :order_url, mp_url: true, if: :order_url?
  validates :payment_model_url, mp_url: true, if: :payment_model_url?
  validates :pricing_url, mp_url: true, if: :pricing_url?
  validates :manual_url, mp_url: true, if: :manual_url?
  validates :helpdesk_url, mp_url: true, if: :helpdesk_url?
  validates :helpdesk_email, allow_blank: true, email: true
  validates :security_contact_email, allow_blank: true, email: true
  validates :privacy_policy_url, mp_url: true, if: :privacy_policy_url?
  validates :training_information_url, mp_url: true, if: :training_information_url?
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
  validates :geographical_availabilities,
            presence: true,
            length: {
              minimum: 1,
              message: "are required. Please add at least one"
            }
  validates :resource_organisation, presence: true
  validates :public_contacts, presence: true, length: { minimum: 1, message: "are required. Please add at least one" }

  after_save :set_first_category_as_main!, if: :main_category_missing?

  after_commit :propagate_to_ess

  def self.popular(count)
    where(status: %i[published unverified]).includes(:providers).order(popularity_ratio: :desc, name: :asc).limit(count)
  end

  def main_category
    @main_category ||= categories.joins(:categorizations).find_by(categorizations: { main: true })
  end

  def set_first_category_as_main!
    categorizations.first&.update(main: true)
  end

  def propagate_to_ess
    public? && !destroyed? ? Service::Ess::Add.call(self) : Service::Ess::Delete.call(id)
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

  def organisation_search_link(target_name, default_path = nil)
    _provider_search_link(target_name, "resource_organisation", default_path)
  end

  def provider_search_link(target_name, default_path = nil)
    _provider_search_link(target_name, "providers", default_path)
  end

  def geographical_availabilities_link(gcap)
    _provider_search_link(gcap, "geographical_availabilities", services_path(geographical_availabilities: gcap))
  end

  private

  def _provider_search_link(target_name, filter_query, default_path = nil)
    search_base_url = Mp::Application.config.search_service_base_url
    enable_external_search = Mp::Application.config.enable_external_search
    if enable_external_search
      search_base_url + "/search/service?q=*&fq=#{filter_query}:(%22#{target_name}%22)"
    else
      default_path || provider_path(self)
    end
  end

  def main_category_missing?
    categorizations.where(main: true).count.zero?
  end
end
