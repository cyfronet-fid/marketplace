# frozen_string_literal: true

class Api::V1::ProjectItemPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.default_oms_administrator?
        scope.all
      else
        scope.joins(:offer).where(offers: { primary_oms_id: user.administrated_oms_ids }).distinct
      end
    end
  end

  def show?
    project_item_managed_by_user? || user.default_oms_administrator?
  end

  def update?
    project_item_managed_by_user?
  end

  def permitted_attributes
    [user_secrets: {}, status: %i[value type]]
  end

  private

  def project_item_managed_by_user?
    user.administrated_omses.include? record.offer.current_oms
  end
end
