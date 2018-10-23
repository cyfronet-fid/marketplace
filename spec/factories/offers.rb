# frozen_string_literal: true

FactoryBot.define do
  factory :offer do
    sequence(:name) { |n| "offer #{n}" }
    sequence(:description) { |n| "offer #{n} description" }
    service
  end
end
