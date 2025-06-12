# frozen_string_literal: true

class ProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published errored])
    end
  end

  def show?
    has_permission = !record.deleted? && !record.unpublished?
    raise ActiveRecord::RecordNotFound unless has_permission
    true
  end

  def data_administrator?
    record.owned_by?(user)
  end
end
