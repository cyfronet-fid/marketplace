# frozen_string_literal: true

FactoryBot.define do
  factory :user_identity do
    association :user
    provider { "checkin" }
    sequence(:uid) { |n| "uid#{n}" }
    email_verified { true }
    primary { false }
  end
end
