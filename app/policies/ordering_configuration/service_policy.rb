# frozen_string_literal: true

class OrderingConfiguration::ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: [:published, :unverified, :errored])
    end
  end

  def show?
    record.published? || record.unverified? || record.errored?
  end
end
