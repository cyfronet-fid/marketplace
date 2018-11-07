# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def permitted_attributes
    [:name]
  end
end
