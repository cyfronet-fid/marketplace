# frozen_string_literal: true

class Catalogue::Delete
  extend VariantOperation

  implementations marketplace: "Catalogue::Delete::Standalone", default: "Catalogue::Delete::Cascading"
end
