# frozen_string_literal: true

class Backoffice::OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.service_portfolio_manager?
        scope.where.not(status: :deleted)
      elsif user.service_owner?
        scope
          .joins(service: :service_user_relationships)
          .where(status: %i[published draft], service: { service_user_relationships: { user: user } })
      else
        Offer.none
      end
    end
  end

  def new?
    (service_portfolio_manager? || record.service.owned_by?(user)) && !service_deleted?
  end

  def create?
    managed? && !service_deleted?
  end

  def edit?
    managed? && !record.deleted? && !service_deleted?
  end

  def update?
    managed? && !service_deleted?
  end

  def destroy?
    managed? && record.persisted? && orderless? && !service_deleted? && other_offers_with_service_order_type?
  end

  def publish?
    managed? && record.persisted? && record.draft?
  end

  def draft?
    managed? && record.persisted? && record.published? && other_offers_with_service_order_type?
  end

  def permitted_attributes
    [
      :id,
      :name,
      :description,
      :bundle_exclusive,
      :order_type,
      :order_url,
      :internal,
      :from,
      :primary_oms_id,
      oms_params: {},
      parameters_attributes: %i[
        type
        name
        hint
        min
        max
        unit
        value_type
        start_price
        step_price
        currency
        exclusive_min
        exclusive_max
        mode
        values
        value
      ]
    ]
  end

  private

  def managed?
    service_portfolio_manager? || record.service.administered_by?(user) || record.service.owned_by?(user)
  end

  def service_portfolio_manager?
    user&.service_portfolio_manager?
  end

  def orderless?
    record.project_items.count.zero?
  end

  def service_deleted?
    record.service.deleted?
  end

  def other_offers_with_service_order_type?
    service = record.service
    offers_with_service_order_type = service.offers.published.select { |o| o.order_type == service.order_type }
    (offers_with_service_order_type - [record]).present?
  end
end
