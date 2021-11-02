# frozen_string_literal: true

FactoryBot.define do
  factory :customizable_project_item do
    status { "created" }
    status_type { :created }
    voucher_id { "" }
    request_voucher { false }

    offer
    project
  end
end
