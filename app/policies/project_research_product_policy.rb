# frozen_string_literal: true

class ProjectResearchProductPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(project: project)
    end
  end

  def permitted_attributes
    %i[project_id research_product_id]
  end
end
