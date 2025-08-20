# frozen_string_literal: true

class Api::V1::Ess::DeployableServicePolicy < Api::V1::EssPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published errored])
    end
  end
end
