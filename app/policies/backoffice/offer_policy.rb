# frozen_string_literal: true

class Backoffice::OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.service_portfolio_manager?
        scope
      elsif user.service_owner?
        scope.joins(:service_user_relationships).
          where(service_user_relationships: { user: user })
      else
        Service.none
      end
    end
  end

  def new?
    service_portfolio_manager? || record.service.owned_by?(user)
  end

  def create?
    managed?
  end

  def edit?
    managed?
  end

  def update?
    managed?
  end

  def destroy?
    managed? && orderless?
  end

  def publish?
    service_portfolio_manager? && record.draft?
  end

  def draft?
    service_portfolio_manager? && record.published?
  end

  def permitted_attributes
    [:name, :description, :webpage, :offer_type, [parameters_as_string: []]]
  end

  private
    def managed?
      service_portfolio_manager? ||
        (record.service.owned_by?(user) && record.draft?)
    end

    def service_portfolio_manager?
      user&.service_portfolio_manager?
    end

    def orderless?
      record.project_items.count.zero?
    end
end
