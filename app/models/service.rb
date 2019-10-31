# frozen_string_literal: true


class Service < ApplicationRecord
  # ELASTICSEARCH
  # scope :search_import working with should_indexe?
  # and define which services are indexed in elasticsearch
  searchkick word_middle: [:title, :tagline, :description], highlight: [:title, :tagline]

  # search_data are definition whitch
  # fields are mapped to elasticsearch
  def search_data
    {
      title: title,
      tagline: tagline,
      description: description,
      status: status,
      rating: rating,
      categories: categories.map(&:id),
      research_areas: research_areas.map(&:id),
      providers: providers.map(&:id),
      platforms: platforms.map(&:id),
      target_groups: target_groups.map(&:id),
      tags: tag_list,
      source: upstream&.source_type
    }
  end

  extend FriendlyId
  friendly_id :title, use: :slugged

  acts_as_taggable

  has_one_attached :logo

  enum service_type: {
    normal: "normal",
    open_access: "open_access",
    catalog: "catalog"
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

  enum status: STATUSES

  has_many :offers, dependent: :restrict_with_error
  has_many :categorizations, dependent: :destroy
  has_many :categories, through: :categorizations
  has_many :service_opinions, through: :project_items
  has_many :service_research_areas, dependent: :destroy
  has_many :research_areas, through: :service_research_areas
  has_many :service_providers, dependent: :destroy
  has_many :providers, through: :service_providers
  has_many :service_related_platforms, dependent: :destroy
  has_many :platforms, through: :service_related_platforms
  has_many :service_target_groups, dependent: :destroy
  has_many :target_groups, through: :service_target_groups

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

  validates :title, presence: true
  validates :description, presence: true
  validates :tagline, presence: true
  validates :connected_url, presence: true, mp_url: true, if: :open_access?
  validates :rating, presence: true
  validates :terms_of_use_url, mp_url: true, if: :terms_of_use_url?
  validates :access_policies_url, mp_url: true, if: :access_policies_url?
  validates :sla_url, mp_url: true, if: :sla_url?
  validates :webpage_url, mp_url: true, if: :webpage_url?
  validates :manual_url, mp_url: true, if: :manual_url?
  validates :helpdesk_url, mp_url: true, if: :helpdesk_url?
  validates :helpdesk_email, allow_blank: true, email: true
  validates :contact_emails, array: { email: true }
  validates :tutorial_url, mp_url: true, if: :tutorial_url?
  validates :logo, blob: { content_type: :image }
  validate :logo_variable, on: [:create, :update]
  validates :research_areas, presence: true
  validates :providers, presence: true
  validates :status, presence: true
  validates :order_target, allow_blank: true, email: true

  after_save :set_first_category_as_main!, if: :main_category_missing?

  def main_category
    @main_category ||= categories.joins(:categorizations).
                                  find_by(categorizations: { main: true })
  end

  def set_first_category_as_main!
    categorizations.first&.update_attributes(main: true)
  end

  def offers?
    offers_count.positive?
  end

  def aod?
    platforms.pluck(:name).include?("EGI Applications on Demand")
  end

  def owned_by?(user)
    service_user_relationships.where(user: user).count.positive?
  end

  private
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
