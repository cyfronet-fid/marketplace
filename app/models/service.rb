# frozen_string_literal: true


class Service < ApplicationRecord
  # ELASTICSEARCH
  # scope :search_import working with should_indexe?
  # and define which services are indexed in elasticsearch
  searchkick text_middle: [:title, :description]
  scope :search_import, -> { where(status: :published) }
  # search_data are definition whitch
  # fields are mapped to elasticsearch
  def search_data
    {
      title: title,
      description: description,
      status: status,
      rating: rating
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
    draft: "draft"
  }

  enum status: STATUSES

  has_many :offers, dependent: :restrict_with_error
  has_many :service_categories, dependent: :destroy
  has_many :categories, through: :service_categories
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
  validates :connected_url, presence: true, url: true, if: :open_access?
  validates :rating, presence: true
  validates :terms_of_use_url, url: true, if: :terms_of_use_url?
  validates :access_policies_url, url: true, if: :access_policies_url?
  validates :corporate_sla_url, url: true, if: :corporate_sla_url?
  validates :webpage_url, url: true, if: :webpage_url?
  validates :manual_url, url: true, if: :manual_url?
  validates :helpdesk_url, url: true, if: :helpdesk_url?
  validates :tutorial_url, url: true, if: :tutorial_url?
  validates :logo, blob: { content_type: :image }
  validates :research_areas, presence: true
  validates :providers, presence: true
  validates :status, presence: true
  validates :order_target, allow_blank: true, email: true

  after_save :set_first_category_as_main!, if: :main_category_missing?
  before_validation :strip_whitespace

  def main_category
    @main_category ||= categories.joins(:service_categories).
                                  find_by(service_categories: { main: true })
  end

  def set_first_category_as_main!
    service_categories.first&.update_attributes(main: true)
  end

  def offers?
    offers_count.positive?
  end

  after_commit on: [:update] do
    # Update categories counters
    service_categories.each(&:touch) if saved_change_to_status
  end

  def aod?
    platforms.pluck(:name).include?("EGI Applications on Demand")
  end

  # should_index? define
  # which records are indexed in elasticsearch
  def should_index?
    published?
  end

  private

    def main_category_missing?
      service_categories.where(main: true).count.zero?
    end

    def strip_whitespace
      self.terms_of_use_url&.strip!
      self.access_policies_url&.strip!
      self.corporate_sla_url&.strip!
      self.webpage_url&.strip!
      self.manual_url&.strip!
      self.helpdesk_url&.strip!
      self.tutorial_url&.strip!
      self.connected_url&.strip!
    end
end
