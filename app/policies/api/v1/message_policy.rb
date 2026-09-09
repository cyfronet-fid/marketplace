# frozen_string_literal: true

class Api::V1::MessagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.default_oms_administrator?
        scope.all
      else
        # Outer join chosen messages with ProjectItem OR Project messageables
        # and look if user is administrating an oms inside their respective offers.primary_oms
        #
        # Written as raw SQL joins (rather than left_outer_joins(project_item: :offer, ...))
        # because Message#project_item/#project scope their association on
        # `messages.messageable_type`, which Rails cannot merge into a join condition
        # here (it self-joins "messages" instead), silently dropping the type filter and
        # matching any project_item/project whose id coincides with messageable_id.
        scope
          .where("offers.primary_oms_id IN (?)", user.administrated_oms_ids)
          .or(scope.where("offers_project_items.primary_oms_id IN (?)", user.administrated_oms_ids))
          .joins(<<~SQL.squish)
            LEFT OUTER JOIN project_items ON project_items.id = messages.messageable_id
              AND messages.messageable_type = 'ProjectItem'
            LEFT OUTER JOIN offers ON offers.id = project_items.offer_id
            LEFT OUTER JOIN projects ON projects.id = messages.messageable_id
              AND messages.messageable_type = 'Project'
            LEFT OUTER JOIN project_items project_items_projects ON project_items_projects.project_id = projects.id
            LEFT OUTER JOIN offers offers_project_items ON offers_project_items.id = project_items_projects.offer_id
          SQL
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
