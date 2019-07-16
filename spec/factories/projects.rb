# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "project #{n}" }
    sequence(:email) { |n| "username#{n}@email.com" }
    sequence(:reason_for_access) { |n| "reason #{n}" }
    sequence(:customer_typology) { |n| "single_user" }
    sequence(:organization) { |n| "organization #{n}" }
    sequence(:department) { |n| "department #{n}" }
    sequence(:webpage) { |n| "http://webpage#{n}.pl" }
    sequence(:user_group_name) { |n| "User group #{n}" }
    sequence(:project_name) { |n| "Project name #{n}" }
    sequence(:research_areas) { |n| [create(:research_area)] }
    sequence(:country_of_customer) { Country::NON_EUROPEAN }
    sequence(:country_of_collaboration) { [ Country::INTERNATIONAL ] }
    sequence(:project_website_url) { "htpps://project_website.url" }
    sequence(:company_name) { |n| "company name #{n}" }
    sequence(:company_website_url) { "https://company_website.url" }
    sequence(:additional_information) { |n| "Additional information #{n}" }
    user
    issue_status { :jira_active }
    issue_id { 1 }
    issue_key { "MP-1" }
  end
end
