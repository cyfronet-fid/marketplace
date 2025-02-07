# frozen_string_literal: true

class ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: Statusable::VISIBLE_STATUSES)
    end
  end

  def order?
    (record.offers.inclusive.size + record.bundles.published.size).positive?
  end

  def offers_show?
    any_published_offers?
  end

  def bundles_show?
    any_published_bundled_offers?
  end

  def errors_show?
    user.coordinator? || data_administrator?
  end

  def data_administrator?
    record.owned_by?(user)
  end

  private

  def any_published_bundled_offers?
    record.bundles.published.size.positive? ||
      (
        record.offers.select(&:bundled?).size.positive? &&
          record
            .offers
            .select(&:bundled?)
            .map(&:bundles)
            .flatten
            .map { |bundle| bundle.service.status }
            .any? { |status| status.in?(Statusable::PUBLIC_STATUSES) }
      )
  end

  def any_published_offers?
    record.offers? && record.offers.any? { |o| !o.bundle_exclusive && o.published? }
  end
end
