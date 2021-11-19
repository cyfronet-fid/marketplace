# frozen_string_literal: true

FactoryBot.define do
  factory :service_source do
    source_type { ServiceSource.source_types.keys.sample }
    sequence(:eid) { |n| n }

    factory :eosc_registry_service_source do
      source_type { :eosc_registry }
    end
  end
end
