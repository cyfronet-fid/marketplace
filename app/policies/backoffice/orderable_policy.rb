# frozen_string_literal: true

class Backoffice::OrderablePolicy < Backoffice::ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.service_portfolio_manager? || user.data_administrator?
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
    managed? && orderless? && !service_deleted?
  end

  def delete?
    managed? && record.persisted? && !service_deleted?
  end

  def draft?
    managed? && record.persisted? && record.published?
  end

  def publish?
    managed? && !record.published? && !service_deleted?
  end

  private

  def managed?
    service_portfolio_manager? || record.service.owned_by?(user)
  end

  def orderless?
    record.project_items.count.zero?
  end

  def service_deleted?
    record.service.deleted?
  end
end
