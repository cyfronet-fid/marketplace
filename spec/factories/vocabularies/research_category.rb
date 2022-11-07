# frozen_string_literal: true

FactoryBot.define do
  factory :research_category, class: "vocabulary/research_category" do
    sequence(:name) { |n| "research category #{n}" }
    sequence(:eid) { |n| "research_category-#{n}" }
    sequence(:description) { |_n| "Super description" }
    sequence(:extras) { |_n| {} }
  end
end
