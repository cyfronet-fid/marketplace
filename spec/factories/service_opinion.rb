# frozen_string_literal: true

FactoryBot.define do
  factory :service_opinion do
    sequence(:rating) { |n| "service #{n} rating" }
    sequence(:opinion) { |n| "service #{n} opinion" }
    order
  end
end
