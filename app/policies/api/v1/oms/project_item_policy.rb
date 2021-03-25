# frozen_string_literal: true

class Api::V1::Oms::ProjectItemPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all # TODO: index policy logic - in authorization task #1883
    end
  end

  def show?
    true # TODO: show policy logic - in authorization task #1883
  end

  def update?
    true # TODO: update policy logic - in authorization task #1883
  end

  def permitted_attributes
    [
      :user_secrets,
      status: [:value, :type]
    ]
  end
end
