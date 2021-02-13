# frozen_string_literal: true

FactoryBot.define do
  factory :pc_category, class: "vocabulary/pc_category" do
    sequence(:name) { |n| "pc_category #{n}" }
    sequence(:eid) { |n| "category-#{n}" }
  end
end
