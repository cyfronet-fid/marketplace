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
    service_portfolio_manager? || data_administrator?
  end

  def show?
    actionable?
  end

  def new?
    service_portfolio_manager?
  end

  def create?
    service_portfolio_manager?
  end

  def edit?
    access?
  end

  def update?
    access?
  end

  def publish?
    access? && !record.published?
  end

  def unpublish?
    access? && !record.unpublished?
  end

  def suspend?
    access? && !record.suspended?
  end

  def destroy?
    access?
  end

  private

  def service_portfolio_manager?
    user&.service_portfolio_manager?
  end

  def data_administrator?
    user&.data_administrator?
  end

  def actionable?
    service_portfolio_manager? || record&.owned_by?(user)
  end

  def access?
    actionable? && !record.deleted?
  end
end
