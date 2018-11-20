# frozen_string_literal: true

require "elasticsearch/model"

class Service < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  extend FriendlyId
  friendly_id :title, use: :slugged

  has_one_attached :logo

  enum service_type: {
    normal: "normal",
    open_access: "open_access",
    catalog: "catalog"
  }


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
  belongs_to :owner,
             class_name: "User",
             optional: true

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

  after_save :set_first_category_as_main!, if: :main_category_missing?

  def main_category
    @main_category ||= categories.joins(:service_categories).
                                  find_by(service_categories: { main: true })
  end

  def set_first_category_as_main!
    service_categories.first&.update_attributes(main: true)
  end

  private

    def main_category_missing?
      service_categories.where(main: true).count.zero?
    end
end
