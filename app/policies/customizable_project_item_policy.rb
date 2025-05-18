# frozen_string_literal: true

class CustomizableProjectItemPolicy < ApplicationPolicy
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
    [
      :service_id,
      :project_id,
      :affiliation_id,
      :customer_typology,
      :access_reason,
      :additional_information,
      :user_group_name,
      :project_owner,
      :project_website_url,
      :company_name,
      :research_area_id,
      :company_website_url,
      :voucher_id,
      :request_voucher,
      :parent_id,
      :additional_comment,
      property_values: permitted_offer_attributes,
      bundled_property_values: permitted_bundled_offers_attributes
    ]
  end

  private

  def permitted_offer_attributes
    to_permitted_attributes(record.offer.attributes)
  end

  def permitted_bundled_offers_attributes
    record.bundle&.offers&.to_h { |o| ["o#{o.id}", to_permitted_attributes(o.attributes)] }
  end

  def to_permitted_attributes(attributes)
    attributes.map { |a| to_permitted_attribute(a) }
  end

  def to_permitted_attribute(attribute)
    attribute.value_schema[:type] == "array" || attribute.type == "select" ? { attribute.id => [] } : attribute.id
  end
end
