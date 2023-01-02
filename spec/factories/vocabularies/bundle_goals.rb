# frozen_string_literal: true

FactoryBot.define do
  factory :bundle_goal, class: "vocabulary/bundle_goal" do
    sequence(:name) { |n| "Bundle Goal #{n}" }
    sequence(:eid) { |n| "bundle_goal-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
