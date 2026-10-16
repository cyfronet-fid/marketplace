# frozen_string_literal: true

class Catalogue::Unpublish
  extend VariantOperation

  implementations marketplace: "Catalogue::Unpublish::Standalone", default: "Catalogue::Unpublish::Cascading"
end
