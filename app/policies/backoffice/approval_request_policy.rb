# frozen_string_literal: true

class Backoffice::ApprovalRequestPolicy < Backoffice::ApplicationPolicy
  class Scope < Scope
    def resolve
      user&.coordinator? ? scope.all : scope.none
    end
  end

  def index?
    access?
  end

  def show?
    access?
  end

  def edit?
    actionable?
  end

  def update?
    actionable?
  end

  def suspend?
    actionable? && !record.suspended?
  end

  def destroy?
    actionable?
  end

  def management_role?
    coordinator? || data_administrator?
  end

  def permitted_attributes
    %i[current_action last_action message]
  end

  private

  def coordinator?
    user&.coordinator?
  end

  def data_administrator?
    user&.data_administrator?
  end

  def access?
    coordinator?
  end

  def actionable?
    access? && !record.deleted?
  end
end
