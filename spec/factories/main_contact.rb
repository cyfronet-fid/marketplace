# frozen_string_literal: true

FactoryBot.define do
  factory :main_contact do
    sequence(:first_name) { |n| "Main #{n}" }
    sequence(:last_name) { |n| "Contact #{n}" }
    sequence(:email) { |n| "main#{n}@contact.com" }
    sequence(:organisation) { |n| "Organisation #{n}" }
    sequence(:position) { |n| "position #{n}" }
  end
end
