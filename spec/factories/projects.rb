# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "project #{n}" }
    sequence(:reason_for_access) { |n| "reason #{n}" }
    sequence(:customer_typology) { |n| "single_user" }
    sequence(:user_group_name) { |n| "User group #{n}" }
    sequence(:project_name) { |n| "Project name #{n}" }
    sequence(:project_website_url) { "htpps://project_website.url" }
    sequence(:company_name) { |n| "company name #{n}" }
    sequence(:company_website_url) { "https://company_website.url" }
    user
    issue_status { :jira_active }
    issue_id { 1 }
    issue_key { "MP-1" }
  end
end
