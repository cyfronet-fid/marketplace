# frozen_string_literal: true
class AddBundlesForBundledOffers < ActiveRecord::Migration[6.1]
  def up
    Offer
      .all
      .select(&:bundle?)
      .each do |offer|
        bundle =
          Bundle.new(
            name: offer.name,
            description: offer.description,
            order_type: offer.order_type,
            service: offer.service,
            main_offer: offer,
            offers: offer.bundled_connected_offers,
            resource_organisation: offer.service.resource_organisation,
            target_users: offer.service.target_users,
            scientific_domains: offer.service.scientific_domains,
            status: offer.status,
            helpdesk_url: offer.service.helpdesk_url
          )
        bundle.set_iid
        bundle.save(validate: false)
      end
  end

  def down
  end
end
