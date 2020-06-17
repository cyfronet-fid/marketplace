# frozen_string_literal: true

FactoryBot.define do
  factory :public_contact do
    sequence(:first_name) { |n| "Public #{n}" }
    sequence(:last_name) { |n| "Contact #{n}" }
    sequence(:email) { |n| "public#{n}@contact.com" }
    sequence(:organisation) { |n| "Organisation #{n}" }
    sequence(:position) { |n| "position #{n}" }
  end
end
