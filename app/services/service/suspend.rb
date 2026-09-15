# frozen_string_literal: true

class Service::Suspend
  extend VariantOperation

  implementations marketplace: "Service::Suspend::Standalone", default: "Service::Suspend::Cascading"
end
