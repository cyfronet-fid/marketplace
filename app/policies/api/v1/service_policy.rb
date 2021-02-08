# frozen_string_literal: true

class Api::V1::ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.administered_by(user).where.not(status: ["deleted"]).order(:id)
    end
  end

  def show?
    administered_by? && !deleted?
  end

  def administered_by?
    record.administered_by?(user)
  end

  private
    def deleted?
      record.deleted?
    end
end
