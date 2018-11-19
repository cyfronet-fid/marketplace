# frozen_string_literal: true

class ResearchArea < ApplicationRecord
  has_ancestry cache_depth: true

  has_many :service_research_areas, autosave: true, dependent: :destroy
  has_many :services, through: :service_research_areas

  validates :name, presence: true
end
