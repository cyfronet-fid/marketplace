# frozen_string_literal: true

class DeployableServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published errored])
    end
  end

  def index?
    true
  end

  def show?
    has_permission = !record.deleted? && !record.draft?
    raise ActiveRecord::RecordNotFound unless has_permission
    true
  end
end
