# frozen_string_literal: true

class Api::V1::Ess::OfferPolicy < Api::V1::EssPolicy
  class Scope < Scope
    def resolve
      # Support both Service and DeployableService via polymorphic orderable
      scope
        .where(status: "published")
        .joins(Offer::LEFT_JOIN_SERVICE_SQL)
        .joins(Offer::LEFT_JOIN_DEPLOYABLE_SERVICE_SQL)
        .where(
          "(offers.orderable_type = 'Service' AND services.status = ?) " \
            "OR (offers.orderable_type = 'DeployableService' AND deployable_services.status = ?)",
          "published",
          "published"
        )
    end
  end
end
