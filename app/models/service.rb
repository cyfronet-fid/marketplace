# frozen_string_literal: true

class Service < ApplicationRecord
  include Rails.application.routes.url_helpers
  include LogoAttachable
  include Publishable
  include Presentable
  include Propagable
  include Viewable
  include Service::Search
  include Statusable
  include OrderableResource

  extend FriendlyId
  friendly_id :name, use: :slugged

  acts_as_taggable

  before_save { self.catalogue = Catalogue.find(catalogue_id) if catalogue_id.present? }
  before_save { self.pid = upstream.eid if upstream_id.present? }

  attr_accessor :catalogue_id, :monitoring_status, :bundle_id, :research_product_types_as_text

  SERVICE_TYPES = %w[Service Datasource].freeze

  scope :visible, -> { where(status: %i[published suspended]) }
  scope :managed_by,
        ->(user) do
          includes(resource_organisation: :data_administrators).where(
            providers: {
              data_administrators: {
                user_id: user&.id
              }
            }
          ).or where(catalogues: { data_administrators: { user_id: user&.id } })
        end
  scope :datasources, -> { where(type: "Datasource") }

  has_one_attached :logo

  enum :order_type,
       {
         open_access: "open_access",
         fully_open_access: "fully_open_access",
         order_required: "order_required",
         other: "other"
       }

  has_many :service_alternative_identifiers
  has_many :alternative_identifiers, through: :service_alternative_identifiers

  has_many :offers, as: :orderable, dependent: :restrict_with_error
  has_many :bundles, dependent: :restrict_with_error
  has_many :project_items, through: :offers
  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :service_opinions, through: :project_items
  has_many :service_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :service_scientific_domains
  has_many :service_providers, dependent: :destroy
  has_many :providers, through: :service_providers, validate: false
  has_many :service_vocabularies, dependent: :destroy
  has_many :nodes, through: :service_vocabularies, source: :vocabulary, source_type: "Vocabulary::Node"
  has_many :access_types, through: :service_vocabularies, source: :vocabulary, source_type: "Vocabulary::AccessType"
  has_many :trls, through: :service_vocabularies, source: :vocabulary, source_type: "Vocabulary::Trl"
  has_many :omses, dependent: :destroy

  accepts_nested_attributes_for :alternative_identifiers, reject_if: :all_blank, allow_destroy: true

  has_many :user_services, dependent: :destroy
  has_many :favourite_users, through: :user_services, source: :user, class_name: "User"

  has_many :service_user_relationships, dependent: :destroy
  has_many :owners, through: :service_user_relationships, source: :user, class_name: "User"

  has_many :sources, class_name: "ServiceSource", dependent: :destroy

  has_many :service_guidelines, dependent: :destroy
  has_many :guidelines, through: :service_guidelines

  accepts_nested_attributes_for :sources,
                                reject_if:
                                  lambda { |attributes| attributes["eid"].blank? || attributes["source_type"].blank? },
                                allow_destroy: true

  belongs_to :upstream, foreign_key: "upstream_id", class_name: "ServiceSource", optional: true
  belongs_to :resource_organisation, class_name: "Provider", optional: false

  has_one :service_catalogue, dependent: :destroy
  has_one :catalogue, through: :service_catalogue

  belongs_to :jurisdiction, class_name: "Vocabulary::Jurisdiction", optional: true
  belongs_to :datasource_classification, class_name: "Vocabulary::DatasourceClassification", optional: true

  auto_strip_attributes :name, nullify: false
  auto_strip_attributes :description, nullify: false
  auto_strip_attributes :terms_of_use_url, nullify: false
  auto_strip_attributes :access_policies_url, nullify: false
  auto_strip_attributes :webpage_url, nullify: false
  auto_strip_attributes :slug, nullify: false
  auto_strip_attributes :order_type, nullify: false
  auto_strip_attributes :order_url, nullify: false
  auto_strip_attributes :privacy_policy_url, nullify: false
  auto_strip_attributes :public_contact_emails, nullify_array: false
  auto_strip_attributes :urls, nullify_array: false
  auto_strip_attributes :research_product_types, nullify_array: false

  validates :type, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :rating, presence: true
  validates :terms_of_use_url, mp_url: true, if: :terms_of_use_url?
  validates :access_policies_url, mp_url: true, if: :access_policies_url?
  validates :webpage_url, mp_url: true, if: :webpage_url?
  validates :order_type, presence: true
  validates :order_url, mp_url: true, if: :order_url?
  validates :privacy_policy_url, mp_url: true, if: :privacy_policy_url?
  validates :public_contact_emails, array: true
  validates :urls, array: true
  validates :logo, blob: { content_type: :image }
  validate :logo_variable, on: %i[create update]
  validates :scientific_domains,
            presence: true,
            length: {
              minimum: 1,
              message: "are required. Please add at least one"
            }
  validates :trls, length: { maximum: 1 }
  validates :nodes, length: { maximum: 1 }
  validates :resource_organisation, presence: true
  validate :public_contact_emails_format

  after_save :set_first_category_as_main!, if: :main_category_missing?

  def self.popular(count)
    includes(:providers).where(status: :published).order(popularity_ratio: :desc, name: :asc).limit(count)
  end

  def main_category
    @main_category ||= categories.joins(:categorizations).find_by(categorizations: { main: true })
  end

  def main_source
    sources.first
  end

  def set_first_category_as_main!
    categorizations.first&.update(main: true)
  end

  def offers?
    offers_count.positive?
  end

  def bundles?
    bundles_count.positive?
  end

  def eosc_if
    tag_list.select { |tag| tag.downcase.start_with?("eosc::") }
  end

  def sliced_tag_list
    tag_list.reject { |tag| tag.downcase.start_with?("eosc::") }
  end

  def aod?
    false
  end

  def activate_message
    nil
  end

  def activate_message=(_value)
    nil
  end

  def owned_by?(user)
    service_user_relationships.where(user: user).size.positive? ||
      (
        resource_organisation.present? && resource_organisation.data_administrators&.map(&:user_id)&.include?(user.id)
      ) || (catalogue.present? && catalogue.data_administrators&.map(&:user_id)&.include?(user.id))
  end

  def organisation_search_link(target, default_path = nil)
    _search_link(target, "resource_organisation", default_path)
  end

  def node_search_link(target, default_path = nil)
    _search_link(target, "node", default_path)
  end

  def provider_search_link(target, default_path = nil)
    _search_link(target, "providers", default_path)
  end

  private

  def _search_link(target_name, filter_query, default_path = nil)
    search_base_url = Mp::Application.config.search_service_base_url
    enable_external_search = Mp::Application.config.enable_external_search
    if enable_external_search
      search_base_url + "/search/service?q=*&fq=#{filter_query}:(%22#{target_name}%22)"
    else
      default_path
    end
  end

  def main_category_missing?
    categorizations.where(main: true).empty?
  end

  def public_contact_emails_format
    Array(public_contact_emails).each do |email|
      errors.add(:public_contact_emails, "#{email} is not a valid email") unless email =~ URI::MailTo::EMAIL_REGEXP
    end
  end
end
