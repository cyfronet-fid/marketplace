# frozen_string_literal: true

class ResearchProductPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(project: user.projects)
    end
  end

  def destroy?
    owner?
  end

  private

  def owner?
    record.projects.map(&:user).include?(user)
  end
end
