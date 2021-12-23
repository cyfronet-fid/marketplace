# frozen_string_literal: true

FactoryBot.define do
  factory :structure_type, class: "vocabulary/structure_type" do
    sequence(:name) { |n| "Structure Type #{n}" }
    sequence(:eid) { |n| "provider_structure_type-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
