# frozen_string_literal: true

class Backoffice::ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(owner: user)
    end
  end

  def index?
    true
  end

  def show?
    owner?
  end

  def new?
    true
  end

  def create?
    true
  end

  def update?
    owner?
  end

  def destroy?
    owner? && project_items.count.zero?
  end

  def permitted_attributes
    [:title, :description, :terms_of_use,
     :tagline, :connected_url, :open_access,
     :provider_id, :places, :languages,
     [dedicated_for: []], :terms_of_use_url,
     :access_policies_url, :corporate_sla_url,
     :webpage_url, :manual_url, :helpdesk_url,
     :tutorial_url, :restrictions, :phase,
     :activate_message, :logo,
     [contact_emails: []], [area_ids: []]]
  end

  private

    def owner?
      record.owner == user
    end

    def project_items
      ProjectItem.joins(:offer).where(offers: { service_id: record })
    end
end
