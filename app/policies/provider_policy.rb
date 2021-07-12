# frozen_string_literal: true

class ProviderPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def data_administrator?
    record.administered_by?(user)
  end
end
