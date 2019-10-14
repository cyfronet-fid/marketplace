# frozen_string_literal: true

FactoryBot.define do
  factory :research_area do
    sequence(:name) { |n| "research area %05d" % n }
  end
end
