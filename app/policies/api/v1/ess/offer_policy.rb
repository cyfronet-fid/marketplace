# frozen_string_literal: true

class Api::V1::Ess::OfferPolicy < Api::V1::EssPolicy
  class Scope < Scope
    def resolve
      scope.joins(:service).where("offers.status = ? AND services.status IN (?)", "published", %w[published unverified])
    end
  end
end
