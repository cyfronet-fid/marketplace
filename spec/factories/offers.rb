# frozen_string_literal: true

FactoryBot.define do
  factory :offer do
    sequence(:iid) { |n| n }
    sequence(:name) { |n| "offer #{n}" }
    sequence(:description) { |n| "offer #{n} description" }
    order_type { :order_required }
    status { :published }
    internal { true }

    # Use orderable polymorphic association instead of direct service association
    transient do
      service { :not_set }
      deployable_service { :not_set }
    end

    # Set orderable based on provided service or deployable_service
    # Priority: service > deployable_service > default service
    # Both transients default to :not_set; when explicitly set (even to nil), use that value
    orderable do
      if service != :not_set
        service.presence || (deployable_service == :not_set ? nil : deployable_service)
      elsif deployable_service != :not_set
        deployable_service
      else
        create(:service, offers_count: 1, order_type: :order_required)
      end
    end
    offer_category { create(:service_category) }

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
      order_type { :open_access }
    end

    factory :fully_open_access_offer do
      order_type { :fully_open_access }
    end

    factory :other_offer do
      order_type { :other }
    end

    factory :external_offer do
      internal { false }
      order_type { :order_required }
      order_url { "http://order.com" }
    end

    factory :voucherable_offer do
      voucherable { true }
    end
  end
end
