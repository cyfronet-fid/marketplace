# frozen_string_literal: true

FactoryBot.define do
  factory :service_category, class: "vocabulary/service_category" do
    sequence(:name) { |n| "ServiceCategory #{n}" }
    sequence(:eid) { |n| "service_category-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }

    factory :service_category_other do
      sequence(:name) { |_n| "Other" }
      sequence(:eid) { |_n| "service_category-other" }
    end
  end
end
