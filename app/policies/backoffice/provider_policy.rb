# frozen_string_literal: true

class Backoffice::ProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    service_portfolio_manager?
  end

  def show?
    service_portfolio_manager?
  end

  def new?
    service_portfolio_manager?
  end

  def create?
    service_portfolio_manager?
  end

  def update?
    service_portfolio_manager?
  end

  def destroy?
    service_portfolio_manager?
  end

  def permitted_attributes
    [:name, sources_attributes: [:id, :source_type, :eid, :_destroy],
     data_administrators_attributes: [:id, :first_name, :last_name, :email, :_destroy]]
  end

  private
    def service_portfolio_manager?
      user&.service_portfolio_manager?
    end
end
