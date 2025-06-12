# frozen_string_literal: true

class CataloguePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published errored])
    end
  end

  def show?
    has_permission = !record.deleted? && !record.draft?
    raise ActiveRecord::RecordNotFound unless has_permission
    true
  end
end
