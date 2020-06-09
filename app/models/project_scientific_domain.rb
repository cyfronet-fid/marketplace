# frozen_string_literal: true

class ProjectScientificDomain < ApplicationRecord
  belongs_to :project
  belongs_to :scientific_domain

  validates :project, presence: true
  validates :scientific_domain, presence: true, uniqueness: { scope: :project_id }
end
