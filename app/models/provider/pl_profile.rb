# frozen_string_literal: true

# 1:1 satellite holding the pl-marketplace-only `providers` fields (see
# arch_docs: docs/rationale/db-schema-comparison.md §3). Only ever populated
# under Mp::Variant.pl? — nil for marketplace/whitelabel via Provider#pl_profile.
class Provider::PlProfile < ApplicationRecord
  belongs_to :provider, class_name: "::Provider", inverse_of: :pl_profile

  serialize :participating_countries, coder: Country::Array

  def participating_countries=(value)
    super(value&.map { |country| Country.for(country) })
  end
end
