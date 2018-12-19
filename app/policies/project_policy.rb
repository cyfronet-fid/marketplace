# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def show?
    record.user == user
  end

  def permitted_attributes
    [:name, :reason_for_access,
     :customer_typology, :user_group_name,
     :project_name, :project_website_url,
     :company_name, :company_website_url]
  end
end
