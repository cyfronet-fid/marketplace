
# frozen_string_literal: true

class CartsPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def show?
    record.user == user
  end

  def create?
    true
  end

  def update?
    record.user == user
  end

  def permitted_attributes
    [:service_id]
  end
end
