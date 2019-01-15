# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "project #{n}" }
    user_group_name { |n| "User group #{n}" }
    project_name { |n| "Project name #{n}" }
    project_website_url { "htpps://project_website.url" }
    company_name { |n| "company name #{n}" }
    company_website_url { "https://company_website.url" }
    user
  end
end
