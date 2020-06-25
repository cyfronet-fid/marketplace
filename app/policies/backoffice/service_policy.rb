# frozen_string_literal: true


EIC_SOURCE_FIELDS = [
  :logo,
  :name,
  :description,
  :tagline,
  [language_availability: []],
  [geographical_availabilities: []],
  :dedicated_for,
  :terms_of_use_url,
  :access_policies_url,
  :sla_url,
  :webpage_url,
  :manual_url,
  :helpdesk_url,
  :training_information_url,
  :status_monitoring_url,
  :maintenance_url,
  :order_url,
  :payment_model_url,
  :pricing_url,
  :order_type,
  [provider_ids: []],
  :version,
  [trl_ids: []],
  [life_cycle_status_ids: []]
]


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

  SOURCES_FIELDS = {
      "eic" => EIC_SOURCE_FIELDS
  }

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
    service_portfolio_manager? || (record.draft? && owned_service?)
  end

  def publish?
    service_portfolio_manager? && (record.draft? || record.unverified?)
  end

  def publish_unverified?
    service_portfolio_manager? && (record.draft? || record.published?)
  end

  def draft?
    service_portfolio_manager? && (record.published? || record.unverified?)
  end

  def preview?
    service_portfolio_manager?
  end

  def destroy?
    service_portfolio_manager? &&
      (project_items && project_items.count.zero?) &&
      record.draft?
  end

  def permitted_attributes
    attrs = [
      :name, :description,
      :tagline, :order_type,
      [provider_ids: []], [geographical_availabilities: []],
      [language_availability: []],
      [target_user_ids: []], :terms_of_use_url,
      :access_policies_url, :sla_url,
      :webpage_url, :manual_url, :helpdesk_url,
      :helpdesk_email, :training_information_url, :restrictions,
      :order_target, :status_monitoring_url, :maintenance_url,
      :order_url, :payment_model_url, :pricing_url,
      [funding_body_ids: []], [funding_program_ids: []],
      :activate_message, :logo, [trl_ids: []],
      [contact_emails: []], [scientific_domain_ids: []],
      [platform_ids: []], :tag_list, [category_ids: []],
      [owner_ids: []], :status, :upstream_id, :version,
      [life_cycle_status_ids: []],
      sources_attributes: [:id, :source_type, :eid, :_destroy]
    ]

    if !@record.is_a?(Service) || @record.upstream.nil?
      attrs
    else
      attrs - SOURCES_FIELDS[@record.upstream.source_type]
    end
  end

  private
    def service_portfolio_manager?
      user&.service_portfolio_manager?
    end

    def service_owner?
      user&.service_owner?
    end

    def owned_service?
      record.owned_by?(user)
    end

    def project_items
      ProjectItem.joins(:offer).where(offers: { service_id: record })
    end
end
