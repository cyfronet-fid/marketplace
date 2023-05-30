# frozen_string_literal: true

class Api::V1::Ess::ProviderPolicy < Api::V1::EssPolicy
  class Scope < Scope
    def resolve
      scope.where(status: "published")
    end
  end
end
