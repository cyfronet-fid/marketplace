# frozen_string_literal: true

class ServiceContextPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      Service.where(status: Statusable::VISIBLE_STATUSES)
    end
  end

  def show?
    permitted?
  end

  def order?
    permitted? && record.service.status.in?(Statusable::PUBLIC_STATUSES) && record.service.offers? &&
      (record.service.offers.inclusive.any?(&:published?) || record.service.bundles.any?(&:published?))
  end

  private

  def permitted?
    service = record.service

    has_permission =
      public_access? ||
        (record.from_backoffice && service.status.in?(Statusable::MANAGEABLE_STATUSES) && additional_access?)
    raise ActiveRecord::RecordNotFound unless has_permission
    true
  end

  def public_access?
    service = record.service

    service.status.in?(Statusable::VISIBLE_STATUSES)
  end

  def additional_access?
    return false if user.blank?
    service = record.service

    user.coordinator? || service.owned_by?(user)
  end
end
