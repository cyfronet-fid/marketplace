# frozen_string_literal: true

FactoryBot.define do
  factory :trigger, class: OMS::Trigger do
    association :oms

    url { "https://example.com" }
    sequence(:method) { :post }

    factory :trigger_method_get do
      sequence(:method) { :get }
    end

    factory :trigger_with_basic_auth do
      sequence(:authorization) { build(:authorization_basic) }
    end
  end
end
