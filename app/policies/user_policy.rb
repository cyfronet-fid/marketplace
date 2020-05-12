# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def show?
    user
  end

  def edit?
    user
  end

  def destroy?
    user
  end

  def permitted_attributes
    [
        :email, [research_area_ids: []],
        [category_ids: []], :research_areas_updates,
        :categories_updates
    ]
  end
end
