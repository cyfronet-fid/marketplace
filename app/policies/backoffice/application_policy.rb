# frozen_string_literal: true

class Backoffice::ApplicationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user&.service_portfolio_manager?
        scope
      elsif user&.data_administrator?
        scope.managed_by(user)
      else
        scope.none
      end
    end
  end

  MP_INTERNAL_FIELDS = [:upstream_id, [sources_attributes: %i[id source_type eid _destroy]]].freeze

  def index?
    service_portfolio_manager? || user&.data_administrator?
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
    access? && !record.deleted?
  end

  def update?
    access? && !record.deleted?
  end

  def destroy?
    access? && !record.deleted?
  end

  private

  def service_portfolio_manager?
    user&.service_portfolio_manager?
  end

  def data_administrator?
    user&.data_administrator?
  end

  def access?
    user&.service_portfolio_manager? || record&.data_administrators&.map(&:email)&.include?(user&.email)
  end
end
