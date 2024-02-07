# frozen_string_literal: true
class OrderingConfiguration::BundlePolicy < Backoffice::BundlePolicy
  class Scope < Scope
    def resolve
      scope.where(status: Statusable::MANAGEABLE_STATUSES)
    end
  end
end
