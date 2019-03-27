# frozen_string_literal: true

FactoryBot.define do
  factory :provider_source do
    source_type { ProviderSource.source_types.keys.sample }
    sequence(:eid) { |n| n }
  end
end
