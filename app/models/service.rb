# frozen_string_literal: true


class Service < ApplicationRecord
  include Service::Search

  extend FriendlyId
  friendly_id :name, use: :slugged

  acts_as_taggable

  has_one_attached :logo

  enum order_type: {
    orderable: "orderable",
    open_access: "open_access",
    external: "external"
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
    draft: "draft"
  }

  SIDEBAR_FIELDS = [{ name: "places_and_languages",
                      template: "array",
                      fields: ["languages"] },
                    { name: "service_availability",
                      template: "map",
                      fields: ["places"] },
                    { name: "platforms",
                      template: "array",
                      fields: ["platforms"] },
                    { name: "support",
                      template: "links",
                      fields: ["webpage_url", "helpdesk_url", "helpdesk_email",
                               "manual_url", "training_information_url"] },
                    { name: "documents",
                      template: "links",
                      fields: ["sla_url", "terms_of_use_url", "access_policies_url"] },
                    { name: "restrictions",
                      template: "text",
                      fields: ["restrictions"] },
                    { name: "phase",
                      template: "text",
                      fields: ["phase"] },
                    { name: "version",
                      template: "plain_text",
                      fields: ["version"] },
                    { name: "last_update",
                      template: "date",
                      fields: ["updated_at"] }]

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
  has_many :service_target_groups, dependent: :destroy
  has_many :target_groups, through: :service_target_groups
  has_many :service_vocabularies, dependent: :destroy
  has_many :funding_bodies, through: :service_vocabularies, source: :vocabulary, source_type: "FundingBody"
  has_many :funding_programs, through: :service_vocabularies, source: :vocabulary, source_type: "FundingProgram"
  has_many :trl, through: :service_vocabularies, source: :vocabulary, source_type: "Trl"
  has_many :life_cycle_status, through: :service_vocabularies, source: :vocabulary, source_type: "LifeCycleStatus"

  has_many :service_user_relationships, dependent: :destroy
  has_many :owners,
           through: :service_user_relationships,
           source: :user,
           class_name: "User"

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
           source: :target
  has_many :sources, source: :service_sources, class_name: "ServiceSource", dependent: :destroy

  accepts_nested_attributes_for :sources,
                                reject_if: lambda { |attributes| attributes["eid"].blank? || attributes["source_type"].blank? },
                                allow_destroy: true

  belongs_to :upstream, foreign_key: "upstream_id", class_name: "ServiceSource", optional: true

  validates :name, presence: true
  validates :description, presence: true
  validates :tagline, presence: true
  validates :rating, presence: true
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
  validates :contact_emails, array: { email: true }
  validates :training_information_url, mp_url: true, if: :training_information_url?
  validates :language_availability, array: true
  validates :logo, blob: { content_type: :image }
  validate :logo_variable, on: [:create, :update]
  validates :scientific_domains, presence: true
  validates :providers, presence: true
  validates :status, presence: true
  validates :order_target, allow_blank: true, email: true
  validates :trl, length: { maximum: 1 }
  validates :life_cycle_status, length: { maximum: 1 }

  after_save :set_first_category_as_main!, if: :main_category_missing?

  def self.popular(count)
    order(popularity_ratio: :desc, name: :asc).limit(count)
  end

  def main_category
    @main_category ||= categories.joins(:categorizations).
                                  find_by(categorizations: { main: true })
  end

  def set_first_category_as_main!
    categorizations.first&.update(main: true)
  end

  def offers?
    offers_count.positive?
  end

  def languages
    language_availability.map { |l| I18nData.languages[l] }
  end

  def aod?
    platforms.pluck(:name).include?("EGI Applications on Demand")
  end

  def owned_by?(user)
    service_user_relationships.where(user: user).count.positive?
  end

  private
    def open_access_or_external?
      open_access? || external?
    end

    def logo_variable
      if logo.present? && !logo.variable?
        errors.add(:logo, "^Sorry, but the logo format you were trying to attach is not supported
                          in the Marketplace. Please attach the logo in png, gif, jpg, jpeg,
                          pjpeg, tiff, vnd.adobe.photoshop or vnd.microsoft.icon format.")
      end
    end

    def main_category_missing?
      categorizations.where(main: true).count.zero?
    end
end
