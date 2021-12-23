# frozen_string_literal: true

FactoryBot.define do
  factory :meril_scientific_domain, class: "vocabulary/meril_scientific_domain" do
    sequence(:name) { |n| "Meril scientific domain #{n}" }
    sequence(:eid) { |n| "provider_meril_scientific_domain-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
