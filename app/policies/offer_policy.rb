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

  def permitted_attributes
    [:name, :description, :webpage, :order_type, :order_url,
     parameters_attributes: [:type, :name, :hint, :min, :max,
                             :unit, :value_type, :start_price, :step_price, :currency,
                             :exclusive_min, :exclusive_max, :mode, :values, :value]]
  end

  private
    def offer_editor?(user)
      DataAdministrator.where(email: user&.email).count.positive? ||
        user&.service_portfolio_manager? ||
        user&.service_owner?
    end
end
