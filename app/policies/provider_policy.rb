# frozen_string_literal: true

class ProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: [:published, :unverified, :errored])
    end
  end

  def show?
    has_permission = !record.deleted?
    raise ActiveRecord::RecordNotFound unless has_permission
    true
  end

  def data_administrator?
    record.administered_by?(user)
  end
end
