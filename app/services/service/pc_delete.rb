# frozen_string_literal: true

class Service::PcDelete
  extend VariantOperation

  implementations marketplace: "Service::PcDelete::Standalone", default: "Service::PcDelete::Cascading"
end
