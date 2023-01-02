# frozen_string_literal: true

class ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published unverified errored])
    end
  end

  def order?
    record.offers? && record.offers.any?(&:published?)
  end

  def offers_show?
    enough_to_show? && any_published_offers?
  end

  def bundles_show?
    any_published_bundled_offers?
  end

  def errors_show?
    user.service_portfolio_manager? || record.administered_by?(user)
  end

  def data_administrator?
    record.administered_by?(user)
  end

  private

  def enough_to_show?
    record.offers? && record.offers.published.size > 1
  end

  def any_published_bundled_offers?
    record.offers? &&
      record.offers.any? { |s| (s.bundled_offers_count.positive? || s.bundles.present?) && s.published? }
  end

  def any_published_offers?
    record.offers? && record.offers.any? { |s| s.bundled_offers_count.zero? && s.published? }
  end
end
