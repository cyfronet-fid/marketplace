# frozen_string_literal: true

class Bundle::Removal
  extend VariantOperation

  implementations marketplace: "Bundle::Destroy", default: "Bundle::Delete"
end
