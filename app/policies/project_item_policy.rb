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

  def permitted_attributes
    attributes =
      record.offer.attributes.map do |a|
        (a.value_schema[:type] == "array" || a.type == "select" ? { a.id => [] } : a.id)
        # TODO: handle other attribute value types
      end
    [
      :service_id,
      :project_id,
      :bundle_id,
      :customer_typology,
      :access_reason,
      :additional_information,
      :user_group_name,
      :project_owner,
      :project_website_url,
      :company_name,
      :scientific_domain_id,
      :parent_id,
      :company_website_url,
      :voucher_id,
      :request_voucher,
      :additional_comment,
      property_values: attributes
    ]
  end
end
