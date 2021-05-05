# frozen_string_literal: true

FactoryBot.define do
  factory :provider do
    sequence(:name) { |n| "provider #{n}" }
    sequence(:pid) { |n| "provider-pid#{n}" }
    factory :provider_admin do
      sequence(:data_administrators)  { |n| [create(:data_administrator)] }
    end
  end
end
