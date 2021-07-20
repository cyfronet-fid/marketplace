# frozen_string_literal: true

class Api::V1::ProjectSerializer < ActiveModel::Serializer
  attribute :id
  attribute :owner
  attribute :project_items
  attribute :attribute_extractor, key: :attributes

  def owner
    {
      uid: object.user.uid,
      email: object.user.email,
      name: object.user.full_name,
      first_name: object.user.first_name,
      last_name: object.user.first_name,
    }
  end

  def project_items
    object.project_items.pluck(:iid)
  end

  def attribute_extractor
    {
      name: object.name,
      customer_typology: object.customer_typology,
      organization: object.organization,
      department: object.department,
      department_webpage: object.webpage,
      scientific_domains: object.scientific_domains&.pluck(:name) || [],
      country: object.country_of_origin&.name,
      collaboration_countries: object.countries_of_partnership&.map(&:name) || [],
      user_group_name: object.user_group_name
    }
  end
end
