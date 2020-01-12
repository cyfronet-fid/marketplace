# frozen_string_literal: true

FactoryBot.define do
  factory :report do
    sequence(:author) { |n| "John Doe #{n}" }
    sequence(:email) { |n| "john.doe#{n}@example.com" }
    sequence(:text) { |n| "Test #{n}" }
  end
end
