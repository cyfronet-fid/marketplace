# frozen_string_literal: true

class Api::V1::Ess::DatasourcePolicy < Api::V1::EssPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published errored], type: "Datasource")
    end
  end
end
