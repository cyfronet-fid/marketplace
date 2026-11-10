# frozen_string_literal: true

class Catalogue::Suspend
  extend VariantOperation

  implementations marketplace: "Catalogue::Suspend::Standalone", default: "Catalogue::Suspend::Cascading"
end
