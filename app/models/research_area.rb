# frozen_string_literal: true

class ResearchArea < ApplicationRecord
  include Parentable

  has_many :service_research_areas, autosave: true, dependent: :destroy
  has_many :services, through: :service_research_areas
  has_many :project_research_areas, autosave: true, dependent: :destroy
  has_many :projects, through: :project_research_areas

  validates :name, presence: true, uniqueness: true

  def self.names
    all.map(&:name)
  end
end
