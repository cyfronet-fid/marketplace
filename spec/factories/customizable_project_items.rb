# frozen_string_literal: true

FactoryBot.define do
  factory :customizable_project_item do
    status { "created" }
    status_type { :created }
    voucher_id { "" }
    request_voucher { false }

    offer
    project

    factory :customizable_project_item_with_voucher do
      voucher_id { "some_voucher_id" }

      offer { build(:voucherable_offer) }
    end
  end
end
