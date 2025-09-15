# frozen_string_literal: true

class Api::V1::Search::ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: Statusable::VISIBLE_STATUSES)
    end
  end

  def index?
    true
  end
end
