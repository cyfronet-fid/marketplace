# frozen_string_literal: true

FactoryBot.define do
  factory :access_mode, class: "vocabulary/access_mode" do
    sequence(:name) { |n| "access mode #{n}" }
    sequence(:eid) { |n| "access_mode-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
