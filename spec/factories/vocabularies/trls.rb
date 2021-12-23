# frozen_string_literal: true

FactoryBot.define do
  factory :trl, class: "vocabulary/trl" do
    sequence(:name) { |n| "Trl #{n}" }
    sequence(:eid) { |n| "trl-#{n}" }
    sequence(:description) { |_n| "Super description" }
    sequence(:extras) { |_n| {} }
  end
end
