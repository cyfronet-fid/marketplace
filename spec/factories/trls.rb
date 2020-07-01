# frozen_string_literal: true

FactoryBot.define do
  factory :trl do
    sequence(:name) { |n| "Trl #{n}" }
    sequence(:eid) { |n| "trl-#{n}" }
    sequence(:description) { |n| "Super description" }
    sequence(:extras) { |n| {} }
  end
end
