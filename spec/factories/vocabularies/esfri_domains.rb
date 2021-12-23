# frozen_string_literal: true

FactoryBot.define do
  factory :esfri_domain, class: "vocabulary/esfri_domain" do
    sequence(:name) { |n| "ESFRI Domain #{n}" }
    sequence(:eid) { |n| "provider_esfri_domain-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
