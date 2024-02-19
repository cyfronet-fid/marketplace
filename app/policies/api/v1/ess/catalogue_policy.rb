# frozen_string_literal: true

class Api::V1::Ess::CataloguePolicy < Api::V1::EssPolicy
  class Scope < Scope
    def resolve
      scope.where(status: "published").where.not(name: "EOSC") # https://github.com/cyfronet-fid/marketplace/issues/3221
    end
  end

  def show?
    # https://github.com/cyfronet-fid/marketplace/issues/3221
    super && record.name != "EOSC"
  end
end
