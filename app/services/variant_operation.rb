# frozen_string_literal: true

# Selects the implementation of an operation for the running deployment
# (Mp::Variant.current). Used during repository consolidation where marketplace
# and pl/whitelabel keep different behavior behind the same operation name.
#
#   class Provider::Suspend
#     extend VariantOperation
#
#     implementations marketplace: "Provider::Suspend::Standalone",
#                     default: "Provider::Suspend::Cascading"
#   end
#
# `Standalone` implementations are marketplace's: they act on the record only
# and run model validations. `Cascading` implementations are pl/whitelabel's:
# they propagate to dependent records and save without validation.
module VariantOperation
  def implementations(**class_names_by_variant)
    @class_names_by_variant = class_names_by_variant
  end

  def implementation
    @class_names_by_variant.fetch(Mp::Variant.current) { @class_names_by_variant.fetch(:default) }.constantize
  end

  def new(...)
    implementation.new(...)
  end

  def call(...)
    implementation.call(...)
  end
end
