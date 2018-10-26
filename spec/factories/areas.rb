# frozen_string_literal: true

FactoryBot.define do
  factory :area do
    sequence(:name) { |n| "area #{n}" }
  end
end
