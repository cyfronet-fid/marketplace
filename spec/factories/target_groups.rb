# frozen_string_literal: true

FactoryBot.define do
  factory :target_group do
    sequence(:name) { |n| "target group #{n}" }
  end
end
