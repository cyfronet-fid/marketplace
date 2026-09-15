# frozen_string_literal: true

class Provider::Delete
  extend VariantOperation

  implementations marketplace: "Provider::Delete::Standalone", default: "Provider::Delete::Cascading"
end
