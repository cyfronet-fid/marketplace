# frozen_string_literal: true

FactoryBot.define do
  factory :esfri_type, class: "vocabulary/esfri_type" do
    sequence(:name) { |n| "ESFRI Type #{n}" }
    sequence(:eid) { |n| "provider_esfri_type-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
