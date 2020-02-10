# frozen_string_literal: true

FactoryBot.define do
  factory :lead_section do
    sequence(:slug) { |n| "slug-#{n}" }
    sequence(:title) { |n| "Lead section #{n}" }
    sequence(:template) { :learn_more }
  end
end
