# frozen_string_literal: true

FactoryBot.define do
  factory :target_user do
    sequence(:name) { |n| "target user #{n}" }
  end
end
