# frozen_string_literal: true

class DatasourcePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published unverified errored])
    end
  end

  def data_administrator?
    record.administered_by?(user)
  end
end
