# frozen_string_literal: true

class Admin::LeadSectionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    admin?
  end

  def create?
    admin?
  end

  def destroy?
    admin?
  end

  def edit?
    admin?
  end

  def update?
    admin?
  end

  def permitted_attributes
    %i[slug title template]
  end

  private

  def admin?
    user&.admin?
  end
end
