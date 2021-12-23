# frozen_string_literal: true

FactoryBot.define do
  factory :funding_program, class: "vocabulary/funding_program" do
    sequence(:name) { |n| "funding_body #{n}" }
    sequence(:eid) { |n| "funding_body-#{n}" }
    sequence(:description) { |_n| "Poland" }
    sequence(:extras) { |_n| {} }
  end
end
