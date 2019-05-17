# frozen_string_literal: true

FactoryBot.define do
  factory :project_item do
    status { :created }
    voucher_id { "" }
    request_voucher { false }

    offer
    project
    affiliation

    research_area { service.open_access? ? nil : create(:research_area) }
  end
end
