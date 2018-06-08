# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    sequence(:title) { |n| "service #{n}" }
    sequence(:description) { |n| "service #{n} description" }
  end
end
