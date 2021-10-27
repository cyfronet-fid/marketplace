# frozen_string_literal: true

FactoryBot.define do
  factory :funding_body, class: "vocabulary/funding_body" do
    sequence(:name) { |n| "funding_body #{n}" }
    sequence(:eid) { |n| "funding_body-#{n}" }
    sequence(:description) { |_n| "Poland" }
    sequence(:extras) { |_n| {} }
  end
end
