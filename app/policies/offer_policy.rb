# frozen_string_literal: true

class OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: :published)
    end
  end

  def index?
    true
  end
end
