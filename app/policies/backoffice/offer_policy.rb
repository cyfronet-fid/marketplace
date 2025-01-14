# frozen_string_literal: true

class Backoffice::OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.service_portfolio_manager? || user.service_owner? || user.data_administrator?
        scope.where.not(status: Statusable::INVISIBLE_STATUSES)
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

  def duplicate?
    managed? && !service_deleted?
  end

  def destroy?
    managed? && record.persisted? && orderless? && !service_deleted? && other_offers_with_service_order_type?
  end

  def publish?
    managed? && record.persisted? && (record.unpublished? || record.draft?)
  end

  def draft?
    managed? && record.persisted? && record.published? && other_offers_with_service_order_type?
  end

  def submit_summary?
    managed? && !service_deleted?
  end

  def permitted_attributes
    [
      :offer_category_id,
      :offer_type_id,
      :offer_subtype_id,
      :id,
      :name,
      :description,
      :bundle_exclusive,
      :order_type,
      :order_url,
      :internal,
      :from,
      :restrictions,
      :primary_oms_id,
      :tag_list,
      oms_params: {
      },
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
