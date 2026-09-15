# frozen_string_literal: true

class Provider::Suspend
  extend VariantOperation

  implementations marketplace: "Provider::Suspend::Standalone", default: "Provider::Suspend::Cascading"
end
