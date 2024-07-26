# frozen_string_literal: true

class Backoffice::BundlePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.service_portfolio_manager? || user.service_owner? || user.data_administrator?
        scope.where.not(status: Statusable::INVISIBLE_STATUSES)
      else
        Service.none
      end
    end
  end

  def new?
    (service_portfolio_manager? || record.service.owned_by?(user)) && !service_deleted?
  end

  def create?
    managed? && !service_deleted?
  end

  def edit?
    managed? && !service_deleted?
  end

  def update?
    managed? && !service_deleted?
  end

  def destroy?
    managed? && orderless? && !service_deleted?
  end

  def delete?
    managed? && record.persisted? && !service_deleted?
  end

  def draft?
    managed? && record.persisted? && record.published?
  end

  def publish?
    managed? && (record.unpublished? || record.draft?)
  end

  def permitted_attributes
    [
      :id,
      :name,
      [bundle_goal_ids: []],
      [capability_of_goals_ids: []],
      :capability_of_goal_suggestion,
      :description,
      :order_type,
      :resource_organisation_id,
      [category_ids: []],
      [scientific_domain_ids: []],
      [target_user_ids: []],
      [research_activity_ids: []],
      :main_offer_id,
      :tag_list,
      :from,
      [offer_ids: []],
      :related_training,
      :related_training_url,
      :contact_email,
      :helpdesk_url,
      parameters_attributes: %i[
        type
        name
        hint
        min
        max
        unit
        value_type
        start_price
        step_price
        currency
        exclusive_min
        exclusive_max
        mode
        values
        value
      ]
    ]
  end

  private

  def managed?
    service_portfolio_manager? || record.service.owned_by?(user)
  end

  def service_portfolio_manager?
    user&.service_portfolio_manager?
  end

  def orderless?
    record.project_items.count.zero?
  end

  def service_deleted?
    record.service.deleted?
  end
end
