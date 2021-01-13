# frozen_string_literal: true

class OrderingConfiguration::OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def new?
    offer_editor?
  end

  def edit?
    offer_editor?
  end

  def create?
    offer_editor?
  end

  def update?
    offer_editor?
  end

  def permitted_attributes
    [:id, :name, :description, :webpage, :order_type, :order_url,
     parameters_attributes: [:type, :name, :hint, :min, :max,
                             :unit, :value_type, :start_price, :step_price, :currency,
                             :exclusive_min, :exclusive_max, :mode, :values, :value]]
  end

  private
    def offer_editor?
      record.service.administered_by?(user) ||
        user&.service_portfolio_manager? ||
        user&.service_owner?
    end
end
