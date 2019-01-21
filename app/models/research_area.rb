# frozen_string_literal: true

class ResearchArea < ApplicationRecord
  has_ancestry cache_depth: true

  has_many :service_research_areas, autosave: true, dependent: :destroy
  has_many :services, through: :service_research_areas
  has_many :project_items, dependent: :restrict_with_exception

  validates :name, presence: true
end
