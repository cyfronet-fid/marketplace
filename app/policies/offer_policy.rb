# frozen_string_literal: true

class OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(:service).where("offers.status = ? AND services.status IN (?)", "published", %w[published unverified])
    end
  end

  def index?
    true
  end
end
