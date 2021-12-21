# frozen_string_literal: true

class ServiceContextPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published unverified errored])
    end
  end

  def show?
    ServiceContextPolicy.permitted?(user, record.service, record.from_backoffice)
  end

  def order?
    ServiceContextPolicy.permitted?(user, record.service, record.from_backoffice) && record.service.offers? &&
      record.service.offers.any? { |s| s.published? }
  end

  def self.permitted?(user, service, from_backoffice = false)
    has_permission =
      ServiceContextPolicy.has_public_access(service) ||
        (service.status === "draft" && ServiceContextPolicy.has_additional_access(user, service) && from_backoffice)
    raise ActiveRecord::RecordNotFound unless has_permission
    true
  end

  private

  def self.has_public_access(record)
    record.published? || record.unverified? || record.errored?
  end

  def self.has_additional_access(user, record)
    return false if user.blank?

    user.service_portfolio_manager? || record.owned_by?(user) || record.administered_by?(user)
  end
end
