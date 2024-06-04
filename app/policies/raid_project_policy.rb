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
      :form_step,
      :start_date,
      :end_date,
      main_title_attributes: %i[id text language start_date end_date],
      alternative_titles_attributes: %i[id text language start_date end_date _destroy],
      main_description_attributes: %i[id text language],
      alternative_descriptions_attributes: %i[id text language _destroy],
      contributors_attributes: [
        :id,
        :pid,
        :pid_type,
        :leader,
        :contact,
        :_destroy,
        [roles: []],
        position_attributes: %i[id pid start_date end_date]
      ],
      raid_organisations_attributes: [:id, :pid, :name, :_destroy, position_attributes: %i[id pid start_date end_date]],
      raid_access_attributes: %i[id access_type statement_text statement_lang embargo_expiry _destroy]
    ]
  end

  private

  def owner?
    record.user == user
  end
end
