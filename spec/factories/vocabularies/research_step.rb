# frozen_string_literal: true

FactoryBot.define do
  factory :research_step, class: "vocabulary/research_step" do
    sequence(:name) { |n| "research step #{n}" }
    sequence(:eid) { |n| "research_step-#{n}" }
    sequence(:description) { |_n| "Super description" }
    sequence(:extras) { |_n| {} }
  end
end
