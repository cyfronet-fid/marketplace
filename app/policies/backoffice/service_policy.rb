# frozen_string_literal: true

class Backoffice::ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      user.service_portfolio_manager? ? scope : Service.none
    end
  end

  def index?
    true
  end

  def show?
    service_portfolio_manager?
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

  def destroy?
    service_portfolio_manager? && project_items.count.zero?
  end

  def permitted_attributes
    [:title, :description, :terms_of_use,
     :tagline, :connected_url, :service_type,
     [provider_ids: []], :places, :languages,
     [target_group_ids: []], :terms_of_use_url,
     :access_policies_url, :corporate_sla_url,
     :webpage_url, :manual_url, :helpdesk_url,
     :tutorial_url, :restrictions, :phase,
     :activate_message, :logo,
     [contact_emails: []], [research_area_ids: []],
     [platform_ids: []], :tag_list, [category_ids: []]]
  end

  private

    # shortcat for service portfolio manager
    def service_portfolio_manager?
      user.service_portfolio_manager?
    end

    def project_items
      ProjectItem.joins(:offer).where(offers: { service_id: record })
    end
end
