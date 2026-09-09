# frozen_string_literal: true

# 1:1 satellite holding the pl-marketplace-only `services` fields (see
# arch_docs: docs/rationale/db-schema-comparison.md §3). Only ever populated
# under Mp::Variant.pl? — nil for marketplace/whitelabel via Service#pl_profile.
class Service::PlProfile < ApplicationRecord
  belongs_to :service, class_name: "::Service", inverse_of: :pl_profile
end
