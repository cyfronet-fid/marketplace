# frozen_string_literal: true

class ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: [:published, :unverified, :errored])
    end
  end

  def order?
    record.offers? && record.offers.any? { |s| s.published? }
  end

  def offers_show?
    record.offers? && record.offers.select { |s| s.bundled_offers_count == 0 && s.published? }.size > 1
  end

  def bundles_show?
    record.offers? && record.offers.any? { |s| s.bundled_offers_count > 0 }
  end

  def data_administrator?
    record.administered_by?(user)
  end
end
