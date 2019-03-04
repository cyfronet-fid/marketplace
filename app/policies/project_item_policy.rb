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
    [:service_id, :project_id, :affiliation_id, :customer_typology,
     :access_reason, :additional_information, :user_group_name,
     :project_name, :project_website_url, :company_name, :research_area_id,
     :company_website_url, :voucher_id, :request_voucher,
     property_values: permitted_offer_attributes,
     bundled_property_values: permitted_bundled_offers_attributes]
  end

  def permitted_offer_attributes
    record.offer.attributes.map { |a| to_permitted_attributes(a) }
  end

  def permitted_bundled_offers_attributes
    record.offer.bundled_offers.
      map { |o| o.attributes }.flatten.
      map { |a| to_permitted_attributes(a) }
  end

  def to_permitted_attributes(attribute)
    if (attribute.value_schema[:type] == "array" || attribute.type == "select")
      { attribute.id => [] }
    else
      attribute.id
    end
  end
end
