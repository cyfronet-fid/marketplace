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
    [:service_id, :project_id]
  end
end
