# frozen_string_literal: true

class DeployableService < ApplicationRecord
  include Rails.application.routes.url_helpers
  include LogoAttachable
  include OrderableResource
  include Publishable
  include Statusable
  include Viewable

  extend FriendlyId
  friendly_id :name, use: :slugged

  acts_as_taggable

  before_save { self.pid = upstream.eid if upstream_id.present? }
  after_create :create_default_offer

  has_one_attached :logo

  has_many :sources, class_name: "DeployableServiceSource", dependent: :destroy
  has_many :deployable_service_scientific_domains, dependent: :destroy
  has_many :scientific_domains, through: :deployable_service_scientific_domains
  has_many :offers, as: :orderable, dependent: :destroy

  belongs_to :upstream, foreign_key: "upstream_id", class_name: "DeployableServiceSource", optional: true
  belongs_to :resource_organisation, class_name: "Provider", optional: false
  belongs_to :catalogue, optional: true
  belongs_to :node_vocabulary, class_name: "Vocabulary::Node", foreign_key: :node, primary_key: :eid, optional: true

  auto_strip_attributes :name, nullify: false
  auto_strip_attributes :description, nullify: false
  auto_strip_attributes :tagline, nullify: false
  auto_strip_attributes :url, nullify: false
  auto_strip_attributes :node, nullify: false
  auto_strip_attributes :version, nullify: false
  auto_strip_attributes :software_license, nullify: false

  validates :name, presence: true
  validates :description, presence: true
  validates :tagline, presence: true
  validates :url, mp_url: true, if: :url?
  validates :logo, blob: { content_type: :image }
  validate :logo_variable, on: %i[create update]

  accepts_nested_attributes_for :sources,
                                reject_if:
                                  lambda { |attributes| attributes["eid"].blank? || attributes["source_type"].blank? },
                                allow_destroy: true

  def to_param
    slug
  end

  def jupyterhub_datamount_template?
    return false if url.blank? && name.blank?

    url&.include?("jupyterhub_datamount.yml") || name&.downcase&.include?("jupyterhub")
  end

  # ============================================================================
  # OrderableResource interface implementation
  # ============================================================================

  # Counts
  def bundles_count
    0
  end

  def offers_count
    offers.count
  end

  # Collections
  def bundles
    Bundle.none
  end

  # Ownership - checks resource_organisation and catalogue data administrators
  def owned_by?(user)
    return false if user.blank?

    (resource_organisation.present? && resource_organisation.data_administrators&.map(&:user_id)&.include?(user.id)) ||
      (catalogue.present? && catalogue.data_administrators&.map(&:user_id)&.include?(user.id))
  end

  # Order type - DeployableServices always require ordering
  def order_type
    "order_required"
  end

  # ============================================================================
  # View compatibility methods
  # ============================================================================

  def rating
    0.0
  end

  def popularity_ratio
    0.0
  end

  def service_opinion_count
    0
  end

  def horizontal
    false
  end

  def main_contact
    nil
  end

  def public_contacts
    []
  end

  def categories
    Category.none
  end

  def target_users
    []
  end

  def geographical_availabilities
    []
  end

  # Provider relationship (returns array to match Service interface)
  def providers
    [resource_organisation].compact
  end

  # ============================================================================
  # Additional Service-compatible methods
  # ============================================================================

  def type
    "DeployableService"
  end

  def webpage_url
    url
  end

  def order_url
    url
  end

  # Service relationships - empty collections
  def related_services
    Service.none
  end

  def required_services
    Service.none
  end

  def manual_related_services
    Service.none
  end

  # Additional collections
  def platforms
    []
  end

  def nodes
    [node_vocabulary].compact
  end

  def service_categories
    []
  end

  def language_availability
    []
  end

  def access_modes
    []
  end

  def access_types
    []
  end

  # Project items through offers (using polymorphic orderable)
  def project_items
    ProjectItem.joins(:offer).where(offers: { orderable_type: "DeployableService", orderable_id: id })
  end

  def project_items_count
    offers.sum(&:project_items_count)
  end

  def service_opinions
    ServiceOpinion.joins(project_item: :offer).where(offers: { orderable_type: "DeployableService", orderable_id: id })
  end

  # Service-specific flags
  def thematic
    false
  end

  def datasource?
    false
  end

  def service?
    false
  end

  def errored?
    status == "errored"
  end

  # URL methods
  def terms_of_use_url
    nil
  end

  def pricing_url
    nil
  end

  def helpdesk_url
    nil
  end

  def manual_url
    nil
  end

  def training_information_url
    nil
  end

  def access_policies_url
    nil
  end

  def resource_level_url
    nil
  end

  # Safe attribute accessors
  def abbreviation
    super || ""
  end

  def tagline
    super || ""
  end

  def description
    super || ""
  end

  # Search and indexing
  def search_data
    { name: name, description: description, tagline: tagline, status: status }
  end

  def should_index?
    published?
  end

  # Analytics (no-op for DeployableService)
  def store_analytics
  end

  def monitoring_status
    nil
  end

  def monitoring_status=(_value)
  end

  # Counter culture compatibility (no-op for DeployableService)
  def increment_counter(_counter_name, _by = 1)
  end

  def decrement_counter(_counter_name, _by = 1)
  end

  private

  def create_default_offer
    return unless jupyterhub_datamount_template?

    DeployableService::CreateDefaultOffer.call(self)
  end

  def logo_variable
    return unless logo.attached? && !logo.variable?

    errors.add(:logo, "Logo should be an image")
  end
end
