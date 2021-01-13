# frozen_string_literal: true

FactoryBot.define do
  factory :data_administrator do
    sequence(:first_name) { |n| "Data #{n}" }
    sequence(:last_name) { |n| "Admin #{n}" }
    sequence(:email) { |n| "data#{n}@admin.com" }
  end
end
