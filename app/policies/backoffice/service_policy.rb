# frozen_string_literal: true

class Backoffice::ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.service_portfolio_manager?
        scope
      elsif user.service_owner?
        scope.joins(:service_user_relationships).
          where(service_user_relationships: { user: user })
      else
        Service.none
      end
    end
  end

  def index?
    service_portfolio_manager? || service_owner?
  end

  def show?
    service_portfolio_manager? || owned_service?
  end

  def new?
    service_portfolio_manager?
  end

  def create?
    service_portfolio_manager?
  end

  def update?
    service_portfolio_manager?
  end

  def publish?
    service_portfolio_manager? && record.draft?
  end

  def draft?
    service_portfolio_manager? && record.published?
  end

  def destroy?
    service_portfolio_manager? &&
      (project_items && project_items.count.zero?) &&
      record.draft?
  end

  def permitted_attributes
    [
      :title, :description, :terms_of_use,
      :tagline, :connected_url, :service_type,
      [provider_ids: []], :places, :languages,
      [target_group_ids: []], :terms_of_use_url,
      :access_policies_url, :corporate_sla_url,
      :webpage_url, :manual_url, :helpdesk_url,
      :tutorial_url, :restrictions, :phase,
      :order_target,
      :activate_message, :logo,
      [contact_emails: []], [research_area_ids: []],
      [platform_ids: []], :tag_list, [category_ids: []],
      [owner_ids: []], :status, :upstream_id,
      sources_attributes: [:id, :source_type, :eid, :_destroy]
    ]
  end

  private

    def service_portfolio_manager?
      user&.service_portfolio_manager?
    end

    def service_owner?
      user&.service_owner?
    end

    def owned_service?
      ServiceUserRelationship.
        where(service: record, user: user).
        count.positive?
    end

    def project_items
      ProjectItem.joins(:offer).where(offers: { service_id: record })
    end
end
