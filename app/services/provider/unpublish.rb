# frozen_string_literal: true

class Provider::Unpublish
  extend VariantOperation

  implementations marketplace: "Provider::Unpublish::Standalone", default: "Provider::Unpublish::Cascading"
end
