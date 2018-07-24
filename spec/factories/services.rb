# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    sequence(:title) { |n| "service #{n}" }
    sequence(:description) { |n| "service #{n} description" }
    sequence(:terms_of_use) { |n| "service #{n} terms of use" }
    sequence(:tagline) { |n| "service #{n} tagline" }
    sequence(:open_access) { false }

    factory :open_access_service do
      sequence(:connected_url) { "https://sample.url" }
      sequence(:open_access) { true }
    end
  end
end
