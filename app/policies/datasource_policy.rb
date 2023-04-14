# frozen_string_literal: true

class DatasourcePolicy < ServicePolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published unverified errored])
    end
  end
end
