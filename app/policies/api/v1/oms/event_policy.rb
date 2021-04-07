# frozen_string_literal: true

class Api::V1::Oms::EventPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all # TODO: implement index scope logic - in authorization task #1883
    end
  end
end
