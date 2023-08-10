# frozen_string_literal: true

class ProjectResearchProduct < ApplicationRecord
  before_destroy :check_and_remove_research_product

  belongs_to :project
  belongs_to :research_product

  validates :project,
            presence: true,
            uniqueness: {
              scope: :research_product,
              message: "Research product already added to selected project"
            }
  validates :research_product, presence: true

  def check_and_remove_research_product
    research_product.delete if research_product.projects.size < 2
  end
end
