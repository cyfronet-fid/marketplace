# frozen_string_literal: true

FactoryBot.define do
  factory :catalogue do
    sequence(:name) { |n| "catalogue #{n}" }
    sequence(:pid) { |n| "catalogue-pid#{n}" }
  end
end
