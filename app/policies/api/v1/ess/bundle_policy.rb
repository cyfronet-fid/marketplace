# frozen_string_literal: true

class Api::V1::Ess::BundlePolicy < Api::V1::EssPolicy
  class Scope < Scope
    def resolve
      scope.joins(:service).where("bundles.status = ? AND services.status = ?", "published", "published")
    end
  end
end
