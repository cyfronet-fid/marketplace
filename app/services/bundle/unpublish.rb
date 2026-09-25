# frozen_string_literal: true

class Bundle::Unpublish
  extend VariantOperation

  implementations marketplace: "Bundle::Unpublish::Standalone", default: "Bundle::Unpublish::Cascading"
end
