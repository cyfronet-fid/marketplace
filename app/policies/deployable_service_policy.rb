# frozen_string_literal: true

class DeployableServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: %i[published errored])
    end
  end

  def index?
    true
  end

  def show?
    has_permission = !record.deleted? && !record.draft?
    raise ActiveRecord::RecordNotFound unless has_permission
    true
  end

  def offers_show?
    any_published_offers?
  end

  def bundles_show?
    any_published_bundled_offers?
  end

  private

  def any_published_offers?
    record.offers? && record.offers.any? { |o| !o.bundle_exclusive && o.published? }
  end

  def any_published_bundled_offers?
    false # DeployableServices don't have bundled offers yet
  end
end
