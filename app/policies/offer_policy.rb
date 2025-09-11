# frozen_string_literal: true

class OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Simple scope: just filter by offer status and bundle_exclusive
      # Let the individual service/deployable_service scopes handle their own authorization
      scope.where(bundle_exclusive: false).where(status: Statusable::PUBLIC_STATUSES)
    end
  end

  def index?
    true
  end

  def order?
    record.published? && (!record.limited_availability || record.availability_count.positive?)
  end

  def disable_notification?
    record.published? && !order? && user&.id.in?(record.user_ids)
  end
end
