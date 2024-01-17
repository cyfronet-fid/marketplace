# frozen_string_literal: true

class BundlePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
        .joins(:service)
        .where("bundles.status = ? AND services.status IN (?)", "published", Statusable::VISIBLE_STATUSES)
    end
  end

  def index?
    true
  end
end
