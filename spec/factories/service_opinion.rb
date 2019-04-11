# frozen_string_literal: true

FactoryBot.define do
  factory :service_opinion do
    sequence(:opinion) { |n| "service #{n} opinion" }
    service_rating { 1 }
    order_rating { 3 }
    project_item
  end
end
