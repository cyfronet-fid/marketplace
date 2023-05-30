# frozen_string_literal: true

class Ess::BundleSerializer < ApplicationSerializer
  attributes :id,
             :name,
             :bundle_goals,
             :capabilities_of_goals,
             :main_offer_id,
             :description,
             :target_users,
             :scientific_domains,
             :research_steps,
             :offer_ids,
             :related_training,
             :contact_email,
             :helpdesk_url,
             :service_id,
             :resource_organisation,
             :providers

  def providers
    ([object.main_offer.service.providers.map(&:name)] + object&.offers&.map { |o| o.service.providers.map(&:name) })
      .flatten.uniq
  end
end
