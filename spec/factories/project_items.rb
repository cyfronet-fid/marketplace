# frozen_string_literal: true

FactoryBot.define do
  factory :project_item do
    status { :created }
    voucher_id { "" }
    request_voucher { false }

    offer
    project
  end
end
