# frozen_string_literal: true

FactoryBot.define do
  factory :offer do
    sequence(:iid) { |n| n }
    sequence(:name) { |n| "offer #{n}" }
    sequence(:description) { |n| "offer #{n} description" }
    sequence(:order_type) { :order_required }
    sequence(:service) { |_n| create(:service, offers_count: 1, order_type: order_type) }
    sequence(:status) { :published }
    sequence(:internal) { true }
    sequence(:offer_category) { |_n| create(:service_category) }

    factory :offer_with_parameters do
      sequence(:parameters) { [build(:input_parameter)] }
    end

    factory :offer_with_all_parameters do
      sequence(:parameters) do
        [
          build(:constant_parameter),
          build(:input_parameter),
          build(:select_parameter),
          build(:multiselect_parameter),
          build(:range_parameter),
          build(:date_parameter),
          build(:quantity_price_parameter)
        ]
      end
    end

    factory :open_access_offer do
      sequence(:order_type) { :open_access }
    end

    factory :fully_open_access_offer do
      sequence(:order_type) { :fully_open_access }
    end

    factory :other_offer do
      sequence(:order_type) { :other }
    end

    factory :external_offer do
      sequence(:internal) { false }
      sequence(:order_type) { :order_required }
      sequence(:order_url) { "http://order.com" }
    end

    factory :voucherable_offer do
      voucherable { true }
    end
  end
end
