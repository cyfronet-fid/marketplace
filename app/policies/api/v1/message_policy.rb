# frozen_string_literal: true

class Api::V1::MessagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.default_oms_administrator?
        scope.all
      else
        # Outer join chosen messages with ProjectItem OR Project messageables
        # and look if user is administrating an oms inside their respective offers.primary_oms
        scope
          .where("offers.primary_oms_id IN (?)", user.administrated_oms_ids)
          .or(scope.where("offers_project_items.primary_oms_id IN (?)", user.administrated_oms_ids))
          .left_outer_joins(project_item: :offer, project: { project_items: :offer })
          .distinct
      end
    end
  end

  def show?
    message_managed_by_user? || user.default_oms_administrator?
  end

  def create?
    write_permissions
  end

  def update?
    write_permissions
  end

  def permitted_attributes_for_create
    [:project_id, :project_item_id, :content, :scope, author: %i[uid email name role]]
  end

  def permitted_attributes_for_update
    [:content]
  end

  private

  def write_permissions
    case record.messageable_type
    when "Project"
      project_message_write_permissions
    when "ProjectItem"
      project_item_message_write_permissions
    end
  end

  def project_message_write_permissions
    if record.public_scope? || record.internal_scope?
      if record.role_provider?
        message_managed_by_user?
      elsif record.role_mediator?
        user.default_oms_administrator?
      elsif record.role_user?
        false
      end
    elsif record.user_direct_scope?
      record.role_mediator? ? user.default_oms_administrator? : false
    end
  end

  def project_item_message_write_permissions
    if record.public_scope? || record.internal_scope?
      if record.role_provider?
        message_managed_by_user?
      elsif record.role_mediator?
        user.default_oms_administrator?
      elsif record.role_user?
        false
      end
    elsif record.user_direct_scope?
      record.role_provider? ? message_managed_by_user? : false
    end
  end

  def message_managed_by_user?
    case record.messageable_type
    when "ProjectItem"
      user.administrated_omses.include? record.messageable.offer.current_oms
    when "Project"
      # Using .map instead of .joins, because we need .current_oms method and not .primary_oms relation
      Set.new(user.administrated_omses).intersect?(
        Set.new(record.messageable.project_items.map(&:offer).map(&:current_oms))
      )
    end
  end
end
