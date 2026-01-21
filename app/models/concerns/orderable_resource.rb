# frozen_string_literal: true

# Shared interface for orderable resources (Service, DeployableService)
# This concern defines the contract that both types must implement
# for the ordering wizard, views, and offer associations to work correctly.
module OrderableResource
  extend ActiveSupport::Concern

  REQUIRED_METHODS = %i[
    name
    description
    tagline
    slug
    status
    order_type
    offers
    bundles
    bundles_count
    offers_count
    resource_organisation
    owned_by?
  ].freeze

  included do
    # Common scopes
    scope :visible, -> { where(status: Statusable::VISIBLE_STATUSES) }
    scope :active, -> { where(status: Statusable::PUBLIC_STATUSES) }
  end

  # Shared implementations
  def offers?
    offers_count.positive?
  end

  def bundles?
    bundles_count.positive?
  end

  def suspended?
    status == "suspended"
  end

  def deleted?
    status == "deleted"
  end

  def draft?
    status == "draft"
  end

  def published?
    status == "published"
  end

  def organisation_search_link(target, default_path = nil)
    _orderable_search_link(target, "resource_organisation", default_path)
  end

  def node_search_link(target, default_path = nil)
    _orderable_search_link(target, "node", default_path)
  end

  def provider_search_link(target, default_path = nil)
    _orderable_search_link(target, "providers", default_path)
  end

  private

  def _orderable_search_link(target_name, filter_query, default_path = nil)
    search_base_url = Mp::Application.config.search_service_base_url
    enable_external_search = Mp::Application.config.enable_external_search

    if enable_external_search
      "#{search_base_url}/search/service?q=*&fq=#{filter_query}:(%22#{target_name}%22)"
    else
      default_path
    end
  end
end
