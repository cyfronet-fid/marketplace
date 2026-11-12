# frozen_string_literal: true

class Api::V1::EventPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      user.default_oms_administrator? ? scope.all : scope.of_omses(user.administrated_oms_ids)
    end
  end
end
