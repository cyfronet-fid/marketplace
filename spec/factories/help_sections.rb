# frozen_string_literal: true

FactoryBot.define do
  factory :help_section do
    sequence(:title) { |n| "Help section #{n}" }
  end
end
