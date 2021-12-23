# frozen_string_literal: true

FactoryBot.define do
  factory :legal_status, class: "vocabulary/legal_status" do
    sequence(:name) { |n| "Legal status #{n}" }
    sequence(:eid) { |n| "provider_legal_status-#{n}" }
    sequence(:description) { |_n| "Poland" }
    sequence(:extras) { |_n| {} }
  end
end
