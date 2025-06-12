# frozen_string_literal: true

class Api::V1::ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where("data_administrators.email = ? AND services.status != ?", user.email, "deleted").joins(
        resource_organisation: [provider_data_administrators: [:data_administrator]]
      )
    end
  end

  def show?
    owned_by? && !record.deleted?
  end

  def owned_by?
    record.owned_by?(user)
  end
end
