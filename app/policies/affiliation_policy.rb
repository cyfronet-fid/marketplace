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
    owner? && !confirmed?
  end

  def update?
    owner? && !confirmed?
  end

  def destroy?
    owner? && !has_project_item?
  end

  def permitted_attributes
    [:organization, :department, :email, :phone, :webpage,
     :supervisor, :supervisor_profile]
  end

  private

    def confirmed?
      record.active?
    end

    def owner?
      record.user == user
    end

    def has_project_item?
      record.project_items.count.positive?
    end
end
