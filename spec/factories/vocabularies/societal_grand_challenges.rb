# frozen_string_literal: true

FactoryBot.define do
  factory :societal_grand_challenge, class: "vocabulary/societal_grand_challenge" do
    sequence(:name) { |n| "Societal grand challenge #{n}" }
    sequence(:eid) { |n| "provider_societal_grand_challenge-#{n}" }
    sequence(:description) { |n| "Super description" }
    sequence(:extras) { |n| {} }
  end
end
