# frozen_string_literal: true

class ProjectResearchArea < ApplicationRecord
  belongs_to :project
  belongs_to :research_area

  validates :project, presence: true
  validates :research_area, presence: true, uniqueness: { scope: :project_id }
end
