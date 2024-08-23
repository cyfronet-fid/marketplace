# frozen_string_literal: true

class Backoffice::ApplicationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.service_portfolio_manager?
        scope.all
      elsif user&.data_administrator?
        scope.managed_by(user)
      else
        scope.none
      end
    end
  end

  MP_INTERNAL_FIELDS = [:upstream_id, [sources_attributes: %i[id source_type eid _destroy]]].freeze

  def index?
    management_role?
  end

  def show?
    access?
  end

  def new?
    service_portfolio_manager?
  end

  def create?
    service_portfolio_manager?
  end

  def edit?
    actionable?
  end

  def update?
    actionable?
  end

  def publish?
    actionable? && !record.published?
  end

  def unpublish?
    actionable? && !record.unpublished?
  end

  def suspend?
    actionable? && !record.suspended?
  end

  def destroy?
    actionable?
  end

  private

  def service_portfolio_manager?
    user&.service_portfolio_manager?
  end

  def data_administrator?
    user&.data_administrator?
  end

  def access?
    service_portfolio_manager? || record&.owned_by?(user)
  end

  def actionable?
    access? && !record.deleted?
  end

  def management_role?
    service_portfolio_manager? || data_administrator?
  end
end
