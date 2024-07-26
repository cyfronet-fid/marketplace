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

  attribute :research_activities, key: :research_activities
  attribute :created_at, key: :publication_date
  attribute :project_items_count, key: :usage_counts_downloads

  def providers
    (
      [object.main_offer.service.providers.map(&:name)] + object&.offers&.map { |o| o.service.providers.map(&:name) }
    ).flatten.uniq
  end

  def catalogues
    object.all_offers.map { |o| o.service.catalogue&.pid }.compact
  end
end
