# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "johndoe#{n}@email.pl" }
    sequence(:first_name) { |n| "John#{n}" }
    sequence(:last_name) { |n| "Doe#{n}" }
    password "12345678"
    sequence(:uid) { |n| "uid#{n}" }
  end
end
