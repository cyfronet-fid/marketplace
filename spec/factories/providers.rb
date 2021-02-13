# frozen_string_literal: true

FactoryBot.define do
  factory :provider do
    sequence(:name) { |n| "provider #{n}" }
    sequence(:pid) { |n| "provider-pid#{n}" }
  end
end
