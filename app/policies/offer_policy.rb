# frozen_string_literal: true

class OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(:service).where(
        "bundle_exclusive = false AND offers.status IN (?) AND services.status IN (?)",
        Statusable::PUBLIC_STATUSES,
        Statusable::VISIBLE_STATUSES
      )
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
