# frozen_string_literal: true

class Service::Removal
  extend VariantOperation

  implementations marketplace: "Service::Destroy", default: "Service::Delete"
end
