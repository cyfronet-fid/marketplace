# frozen_string_literal: true

class Offer::Removal
  extend VariantOperation

  implementations marketplace: "Offer::Destroy", default: "Offer::Delete"
end
