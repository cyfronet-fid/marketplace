# frozen_string_literal: true

class OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: :published)
    end
  end

  def index?
    true
  end

  def edit?
    offer_editor?(user)
  end

  def new?
    offer_editor?(user)
  end

  def update?
    offer_editor?(user)
  end

  def create?
    offer_editor?(user)
  end

  private
    def offer_editor?(user)
      DataAdministrator.where(email: user&.email).count.positive? ||
        user&.service_portfolio_manager? ||
        user&.service_owner?
    end
end
