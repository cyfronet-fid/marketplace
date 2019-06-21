# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def show?
    owner?
  end

  def edit?
    owner?
  end

  def update?
    owner?
  end

  def destroy?
    owner? && !has_project_item?
  end

  def permitted_attributes
    [:name, :reason_for_access, :email,
     :country_of_customer, [country_of_collaboration: []],
     :customer_typology, :user_group_name,
     :organization, :deparment, :webpage,
     :project_name, :project_website_url,
     :company_name, :company_website_url,
     :additional_information]
  end

  private
    def owner?
      record.user == user
    end

    def has_project_item?
      record.project_items.count.positive?
    end
end
