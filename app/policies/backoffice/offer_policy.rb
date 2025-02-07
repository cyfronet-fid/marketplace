# frozen_string_literal: true

class Backoffice::OfferPolicy < Backoffice::OrderablePolicy
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

  def destroy?
    super && other_offers_with_service_order_type?
  end

  def duplicate?
    managed? && !service_deleted?
  end

  private

  def managed?
    coordinator? || record.service.owned_by?(user) || record.service.owned_by?(user)
  end

  def coordinator?
    user&.coordinator?
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
