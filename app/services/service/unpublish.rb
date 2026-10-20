# frozen_string_literal: true

class Service::Unpublish
  extend VariantOperation

  implementations marketplace: "Service::Unpublish::Standalone", default: "Service::Unpublish::Cascading"
end
