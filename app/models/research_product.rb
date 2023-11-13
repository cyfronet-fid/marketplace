# frozen_string_literal: true

class ResearchProduct < ApplicationRecord
  extend FriendlyId
  friendly_id :resource_id

  has_many :project_research_products, dependent: :destroy
  has_many :projects, through: :project_research_products

  validates :resource_id, presence: true
  validates :resource_type, presence: true

  def author=(author)
    self.authors = author.is_a?(Array) ? author : [author]
  end

  def type=(type)
    self.resource_type = type
  end

  def public_attributes
    attributes.slice("title", "authors", "links", "resource_type", "best_access_right")
  end
end
