# frozen_string_literal: true

FactoryBot.define do
  factory :provider_source do
    source_type { ProviderSource.source_types.keys.sample }
    sequence(:eid) { |n| n }

    factory :eosc_registry_provider_source do
      source_type { :eosc_registry }
    end
  end
end
