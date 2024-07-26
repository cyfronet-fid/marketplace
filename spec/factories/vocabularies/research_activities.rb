# frozen_string_literal: true

FactoryBot.define do
  factory :research_activity, class: "vocabulary/research_activity" do
    sequence(:name) { |n| "research activity #{n}" }
    sequence(:eid) { |n| "research_activity-#{n}" }
    sequence(:description) { |_n| "Super description" }
    sequence(:extras) { |_n| {} }
  end
end
