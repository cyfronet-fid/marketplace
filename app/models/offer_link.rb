# frozen_string_literal: true

class OfferLink < ApplicationRecord
  belongs_to :source,
             class_name: "Offer",
             inverse_of: "target_offer_links",
             counter_cache: :bundled_offers_count

  belongs_to :target,
             class_name: "Offer",
             inverse_of: "source_offer_links"
end
