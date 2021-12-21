# frozen_string_literal: true

class Api::V1::ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.default_oms_administrator?
        scope.all
      else
        scope
          .joins(project_items: :offer)
          .where({ project_items: { offers: { primary_oms_id: user.administrated_oms_ids } } })
          .distinct
      end
    end
  end

  def show?
    project_managed_by_user? || user.default_oms_administrator?
  end

  private

  def project_managed_by_user?
    # Using .map instead of .joins, because we need .current_oms method and not .primary_oms relation
    Set.new(user.administrated_omses).intersect?(Set.new(record.project_items.map(&:offer).map(&:current_oms)))
  end
end
