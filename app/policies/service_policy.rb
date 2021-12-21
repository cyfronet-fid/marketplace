# frozen_string_literal: true

class ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published unverified errored])
    end
  end

  def order?
    record.offers? && record.offers.any? { |s| s.published? }
  end

  def offers_show?
    enough_to_show? && has_offers?
  end

  def bundles_show?
    has_bundled_offers?
  end

  def data_administrator?
    record.administered_by?(user)
  end

  private

  def enough_to_show?
    record.offers? && record.offers.published.size > 1
  end

  def has_bundled_offers?
    record.offers? && record.offers.any? { |s| s.bundled_offers_count > 0 && s.published? }
  end

  def has_offers?
    record.offers? && record.offers.any? { |s| s.bundled_offers_count == 0 && s.published? }
  end
end
