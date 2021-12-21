# frozen_string_literal: true

class Admin::LeadPolicy < ApplicationPolicy
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
    %i[header position body picture lead_section_id url]
  end

  private

  def admin?
    user&.admin?
  end
end
