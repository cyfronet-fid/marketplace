# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "project #{n}" }
    user
  end
end
