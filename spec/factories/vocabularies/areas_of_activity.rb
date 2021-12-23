# frozen_string_literal: true

FactoryBot.define do
  factory :area_of_activity, class: "vocabulary/area_of_activity" do
    sequence(:name) { |n| "Area of Activity #{n}" }
    sequence(:eid) { |n| "provider_area_of_activity-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
