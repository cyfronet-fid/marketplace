# frozen_string_literal: true

FactoryBot.define do
  factory :oms do
    sequence(:name) { |n| "OMS #{n}" }
    sequence(:trigger_url) { |n| "http://webhook#{n}.com" }
    sequence(:administrators) { build_list(:user, 2) }
    type { "global" }

    factory :provider_group_oms do
      type { "provider_group" }
      sequence(:providers) { build_list(:provider, 2) }
    end

    factory :resource_dedicated_oms do
      type { "resource_dedicated" }
      sequence(:service) { build(:service) }
    end
  end
end
