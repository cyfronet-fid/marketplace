# frozen_string_literal: true

class Ess::BundleSerializer < ApplicationSerializer
  attributes :id,
             :iid,
             :name,
             :catalogues,
             :bundle_goals,
             :capabilities_of_goals,
             :main_offer_id,
             :description,
             :tag_list,
             :eosc_if,
             :target_users,
             :scientific_domains,
             :offer_ids,
             :related_training,
             :contact_email,
             :helpdesk_url,
             :service_id,
             :resource_organisation,
             :providers,
             :usage_counts_views,
             :updated_at

  attribute :marketplace_locations, key: :research_steps
  attribute :created_at, key: :publication_date
  attribute :project_items_count, key: :usage_counts_downloads

  def providers
    # Use parent_service to support both Service and DeployableService offers
    main_providers = object.main_offer.parent_service&.providers&.map(&:name) || []
    other_providers = object&.offers&.flat_map { |o| o.parent_service&.providers&.map(&:name) || [] } || []
    (main_providers + other_providers).flatten.uniq
  end

  def catalogues
    # Use parent_service to support both Service and DeployableService offers
    object.all_offers.filter_map { |o| o.parent_service&.catalogue&.pid }
  end
end
