# frozen_string_literal: true

require "elasticsearch/model"

class Service < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  extend FriendlyId
  friendly_id :title, use: :slugged

  acts_as_taggable

  has_one_attached :logo

  enum service_type: {
    normal: "normal",
    open_access: "open_access",
    catalog: "catalog"
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
  validates :categories, presence: true
  validates :status, presence: true

  after_save :set_first_category_as_main!, if: :main_category_missing?

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

  private

    def main_category_missing?
      service_categories.where(main: true).count.zero?
    end
end
