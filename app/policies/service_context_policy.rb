# frozen_string_literal: true

class ServiceContextPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published unverified errored])
    end
  end

  def show?
    permitted?
  end

  def order?
    permitted? && record.service.offers? && record.service.offers.any?(&:published?)
  end

  private

  def permitted?
    service = record.service
    from_backoffice = record.from_backoffice || false

    has_permission = public_access? || (service.draft? && additional_access? && from_backoffice)
    raise ActiveRecord::RecordNotFound unless has_permission
    true
  end

  def public_access?
    service = record.service

    service.published? || service.unverified? || service.errored?
  end

  def additional_access?
    return false if user.blank?
    service = record.service

    user.service_portfolio_manager? || service.owned_by?(user) || service.administered_by?(user)
  end
end
