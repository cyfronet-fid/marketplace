# frozen_string_literal: true

class RaidProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
  def index?
    owner?
  end
  def show?
    owner?
  end
  def new?
    owner?
  end

  def create?
    owner?
  end
  def edit?
    owner?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end
  def permitted_attributes
    [
      :start_date,
      :end_date,
      [main_title_attributes: %i[id text language start_date end_date]],
      [alternative_titles_attributes: %i[id text language start_date end_date _destroy]]
    ]
  end

  private

  def owner?
    record.user == user
  end
end
