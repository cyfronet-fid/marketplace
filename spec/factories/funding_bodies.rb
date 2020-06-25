# frozen_string_literal: true

FactoryBot.define do
  factory :funding_body do
    sequence(:name) { |n| "funding_body #{n}" }
    sequence(:eid) { |n| "funding_body-#{n}" }
    sequence(:description) { |n| "Poland" }
    sequence(:extras) { |n| {} }
  end
end
