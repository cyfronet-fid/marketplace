# frozen_string_literal: true

FactoryBot.define do
  factory :project_item do
    status { "created" }
    status_type { :created }
    voucher_id { "" }
    request_voucher { false }

    offer
    project

    factory :project_item_with_voucher do
      voucher_id { "some_voucher_id" }

      offer { build(:voucherable_offer) }
    end
  end
end
