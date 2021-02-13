# frozen_string_literal: true

FactoryBot.define do
  factory :provider_life_cycle_status, class: "vocabulary/provider_life_cycle_status" do
    sequence(:name) { |n| "provider life cycle status #{n}" }
    sequence(:eid) { |n| "provider_life_cycle_status-#{n}" }
    sequence(:description) { |n| "Super description" }
    sequence(:extras) { |n| {} }
  end
end
