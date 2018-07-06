# frozen_string_literal: true

FactoryBot.define do
  factory :affiliation do
    sequence(:organization) { |n| "organization #{n}" }
    sequence(:department) { |n| "department #{n}" }
    sequence(:email) { |n| "user@organization#{n}.pl" }
    sequence(:webpage) { |n| "www.organization#{n}.pl" }
    sequence(:supervisor) { |n| "supervisor#{n}" }
    sequence(:supervisor_profile) { |n| "http://supervisor#{n}.edu" }
    user
  end
end
