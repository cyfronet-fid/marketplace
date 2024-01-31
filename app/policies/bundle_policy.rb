# frozen_string_literal: true

class BundlePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(:service).where(
        "bundles.status IN (?) AND services.status IN (?)",
        Statusable::PUBLIC_STATUSES,
        Statusable::VISIBLE_STATUSES
      )
    end
  end

  def index?
    true
  end

  def show?
    record.service.in?(Statusable::PUBLIC_STATUSES) && record.status.in?(Statusable::PUBLIC_STATUSES)
  end
end
