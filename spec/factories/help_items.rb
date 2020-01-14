# frozen_string_literal: true

FactoryBot.define do
  factory :help_item do
    sequence(:title) { |n| "Help item #{n}" }
    sequence(:content) { |n| "Help content #{n}" }
    help_section
  end
end
