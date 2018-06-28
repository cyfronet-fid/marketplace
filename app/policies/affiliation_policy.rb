# frozen_string_literal: true

class AffiliationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def index?
    user
  end

  def show?
    owner?
  end

  def create?
    user
  end

  def edit?
    owner?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  def permitted_attributes
    [:organization, :department, :email, :phone, :webpage,
     :supervisor, :supervisor_profile]
  end

  private

    def owner?
      record.user == user
    end
end
