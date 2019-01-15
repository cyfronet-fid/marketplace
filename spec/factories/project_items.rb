# frozen_string_literal: true

FactoryBot.define do
  factory :project_item do
    status :created
    customer_typology { ProjectItem.customer_typologies.keys.sample }
    access_reason { |n| "Reason #{n}" }
    additional_information { |n| "Additional information #{n}" }
    user_group_name { |n| "User group #{n}" }
    project_name { |n| "Project name #{n}" }
    project_website_url { "https://project_website.url" }
    company_name { |n| "company name #{n}" }
    company_website_url { "https://company_website.url" }

    properties []

    offer
    project
    affiliation
  end
end
