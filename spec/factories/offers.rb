# frozen_string_literal: true

FactoryBot.define do
  factory :offer do
    sequence(:name) { |n| "offer #{n}" }
    sequence(:description) { |n| "offer #{n} description" }
    sequence(:service) { |n| create(:service, offers_count: 1) }
    sequence(:status) { :published }
    sequence(:webpage) { |n| "http://webpage#{n}.invalid" }
    sequence(:order_type) { :orderable }
    factory :offer_with_parameters do
      sequence(:parameters) { [build(:input_parameter)] }
    end

    factory :open_access_offer do
      sequence(:order_type) { :open_access }
    end
    factory :external_offer do
      sequence(:order_type) { :external }
    end
  end
end
