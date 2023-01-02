# frozen_string_literal: true

FactoryBot.define do
  factory :bundle_capability_of_goal, class: "vocabulary/bundle_capability_of_goal" do
    sequence(:name) { |n| "Capability #{n}" }
    sequence(:eid) { |n| "bundle_capability_of_goal-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
