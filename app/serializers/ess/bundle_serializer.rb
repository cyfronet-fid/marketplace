# frozen_string_literal: true

class Ess::BundleSerializer < ApplicationSerializer
  attributes :id,
             :iid,
             :name,
             :bundle_goals,
             :capabilities_of_goals,
             :main_offer_id,
             :description,
             :tag_list,
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
    ([object.main_offer.service.providers.map(&:name)] + object&.offers&.map { |o| o.service.providers.map(&:name) })
      .flatten.uniq
  end
end
