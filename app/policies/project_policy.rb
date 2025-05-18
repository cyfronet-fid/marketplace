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
    owner? && record.active?
  end

  def update?
    owner?
  end

  def destroy?
    owner? && !any_project_item?
  end

  def archive?
    owner? && !record.archived? && record.project_items.any? && project_items_closed?
  end

  def permitted_attributes
    [
      :name,
      :reason_for_access,
      :email,
      :country_of_origin,
      [countries_of_partnership: []],
      :customer_typology,
      :user_group_name,
      :organization,
      :department,
      :webpage,
      :project_owner,
      :project_website_url,
      :company_name,
      :company_website_url,
      [scientific_domain_ids: []],
      :additional_information
    ]
  end

  private

  def owner?
    record.user == user
  end

  def any_project_item?
    record.project_items.count.positive?
  end

  def project_items_closed?
    record.project_items.all? { |p_i| p_i.closed? || p_i.rejected? }
  end
end
