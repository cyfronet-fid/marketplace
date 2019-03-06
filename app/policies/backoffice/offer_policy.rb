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
    service_portfolio_manager?
  end

  def create?
    service_portfolio_manager?
  end

  def edit?
    service_portfolio_manager?
  end

  def update?
    service_portfolio_manager?
  end

  def destroy?
    service_portfolio_manager? &&
      project_items.count.zero?
  end

  def publish?
    service_portfolio_manager? &&
      record.draft?
  end

  def draft?
    service_portfolio_manager? &&
      record.published?
  end

  def permitted_attributes
    [:name, :description, :offer_type, [parameters_as_string: []]]
  end

  private

    def service_portfolio_manager?
      user.service_portfolio_manager?
    end

    def project_items
      ProjectItem.joins(:offer).where(offers: { service_id: record.service })
    end
end
