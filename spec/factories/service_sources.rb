# frozen_string_literal: true

FactoryBot.define do
  factory :service_source do
    source_type { ServiceSource.source_types.keys.sample }
    sequence(:eid) { |n| n }
  end
end
