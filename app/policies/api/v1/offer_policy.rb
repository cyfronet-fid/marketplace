# frozen_string_literal: true

class Api::V1::OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Only Service offers are exposed through this API (DeployableService has its own flow)
      scope
        .joins(Offer::JOIN_SERVICE_SQL)
        .joins("INNER JOIN providers ON providers.id = services.resource_organisation_id")
        .joins("INNER JOIN provider_data_administrators ON provider_data_administrators.provider_id = providers.id")
        .joins(
          "INNER JOIN data_administrators " \
            "ON data_administrators.id = provider_data_administrators.data_administrator_id"
        )
        .where(
          "data_administrators.email = ? AND offers.status = ? AND services.status != ?",
          user.email,
          "published",
          "deleted"
        )
    end
  end

  def show?
    service_owned_by? && !service_deleted? && record.published?
  end

  def create?
    service_owned_by? && !service_deleted? && record.published?
  end

  def update?
    service_owned_by? && !service_deleted? && record.published?
  end

  def destroy?
    service_owned_by? && !service_deleted? && record.published?
  end

  def permitted_attributes
    [
      :name,
      :description,
      :order_type,
      :order_url,
      :offer_category,
      :primary_oms_id,
      :internal,
      oms_params: {
      },
      parameters: [
        :id,
        :type,
        :label,
        :description,
        :unit,
        :value_type,
        :value,
        config: [
          :mode,
          :minimum,
          :maximum,
          :minItems,
          :maxItems,
          :exclusiveMinimum,
          :exclusiveMaximum,
          :start_price,
          :step_price,
          :currency,
          values: []
        ]
      ]
    ]
  end

  private

  def service_owned_by?
    # Use parent_service to support both Service and DeployableService
    record.parent_service&.owned_by?(user) || false
  end

  def service_deleted?
    # Use parent_service to support both Service and DeployableService
    record.parent_service&.deleted? || false
  end
end
