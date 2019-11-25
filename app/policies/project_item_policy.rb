# frozen_string_literal: true

class ProjectItemPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.user == user
  end

  def new?
    user
  end

  def create?
    user && record.project&.user == user
  end

  def conversation?
    record&.offer.orderable?
  end

  def permitted_attributes
    attributes = record.offer.attributes.map { |a|
      (a.value_schema[:type] == "array" || a.type == "select" ? { a.id => [] } : a.id)
      # TODO handle other attribute value types
    }
    [:service_id, :project_id, :customer_typology,
     :access_reason, :additional_information, :user_group_name,
     :project_name, :project_website_url, :company_name, :research_area_id,
     :company_website_url, :voucher_id, :request_voucher, property_values: attributes]
  end
end
