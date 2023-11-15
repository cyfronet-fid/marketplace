# frozen_string_literal: true

FactoryBot.define do
  factory :marketplace_location, class: "vocabulary/marketplace_location" do
    sequence(:name) { |n| "marketplace location #{n}" }
    sequence(:eid) { |n| "marketplace_location-#{n}" }
    sequence(:description) { |_n| "Super description" }
    sequence(:extras) { |_n| {} }
  end
end
