# frozen_string_literal: true

FactoryBot.define do
  factory :deployable_service_source do
    sequence(:eid) { |n| "eosc.deployable_service.#{n}" }
    source_type { "eosc_registry" }
    association :deployable_service
  end
end
