# frozen_string_literal: true

FactoryBot.define do
  factory :life_cycle_status do
    sequence(:name) { |n| "life cycle status #{n}" }
    sequence(:eid) { |n| "life_cycle_status-#{n}" }
    sequence(:description) { |n| "Super description" }
    sequence(:extras) { |n| {} }
  end
end
