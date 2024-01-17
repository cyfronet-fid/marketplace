# frozen_string_literal: true

class OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
        .joins(:service)
        .where("offers.status = ? AND services.status IN (?)", "published", Statusable::VISIBLE_STATUSES)
    end
  end

  def index?
    true
  end
end
