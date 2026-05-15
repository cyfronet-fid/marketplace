# frozen_string_literal: true

FactoryBot.define do
  factory :vocabulary_jurisdiction, class: "vocabulary/jurisdiction" do
    sequence(:name) { |n| "Jurisdiction #{n}" }
    sequence(:eid) { |n| "jurisdiction-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
