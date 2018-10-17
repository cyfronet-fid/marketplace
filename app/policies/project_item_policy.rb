# frozen_string_literal: true

class ProjectItemPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def index?
    true
  end

  def show?
    record.user == user
  end

  def new?
    user
  end

  def create?
    user
  end

  def permitted_attributes
    [:service_id]
  end
end
