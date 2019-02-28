# frozen_string_literal: true

class OfferLink < ApplicationRecord
  belongs_to :source,
             class_name: "Offer",
             foreign_key: "source_id",
             inverse_of: "target_offer_links",
             counter_cache: :bundled_offers_count

  belongs_to :target,
             class_name: "Offer",
             foreign_key: "target_id",
             inverse_of: "source_offer_links"
end
