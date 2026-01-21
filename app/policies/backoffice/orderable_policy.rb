# frozen_string_literal: true

class Backoffice::OrderablePolicy < Backoffice::ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.coordinator? || user.data_administrator?
        scope.where.not(status: Statusable::INVISIBLE_STATUSES)
      else
        scope.none
      end
    end
  end

  def new?
    managed? && !service_deleted?
  end

  def create?
    managed? && !service_deleted?
  end

  def edit?
    managed? && !service_deleted?
  end

  def update?
    managed? && !service_deleted?
  end

  def destroy?
    status_change? && orderless? && !service_deleted?
  end

  def delete?
    status_change? && !service_deleted?
  end

  def draft?
    status_change? && record.published?
  end

  def publish?
    status_change? && !record.published? && !service_deleted?
  end

  private

  def status_change?
    managed? && record.persisted?
  end

  def managed?
    # Use parent_service to support both Service and DeployableService offers
    coordinator? || record.parent_service&.owned_by?(user) || false
  end

  def orderless?
    record.project_items.empty?
  end

  def service_deleted?
    # Use parent_service to support both Service and DeployableService offers
    record.parent_service&.deleted? || false
  end
end
