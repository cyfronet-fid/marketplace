# frozen_string_literal: true

FactoryBot.define do
  factory :project_item do
    status :created
    customer_typology { ProjectItem.customer_typologies.keys.sample }
    access_reason { |n| "Reason #{n}" }
    additional_information { |n| "Additional information #{n}" }
    properties []

    offer
    project
    affiliation
  end
end
