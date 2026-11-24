# frozen_string_literal: true

# The Statistics API. Any user with a valid token reads it, with no role, so
# the Resource Catalogue's user needs no coordinator role, and its token reads
# statistics and nothing else.
class Api::V1::StatisticsPolicy < ApplicationPolicy
  # The Services the API publishes: published or errored, Datasources
  # included, as in ESS.
  class Scope < Scope
    def resolve
      scope.active
    end
  end

  def index?
    user.present?
  end

  def show?
    user.present?
  end
end
