# frozen_string_literal: true

class Api::V1::Oms::MessagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all # TODO: implement index scope logic - in authorization task #1883
    end
  end

  def create?
    true # TODO: show policy logic - in authorization task #1883
  end

  def update?
    true # TODO: update policy logic - in authorization task #1883
  end

  def permitted_attributes_for_create
    [
      :project_id,
      :project_item_id,
      :content,
      :scope,
      author: [:email, :name, :role]
    ]
  end

  def permitted_attributes_for_update
    [:content]
  end
end
