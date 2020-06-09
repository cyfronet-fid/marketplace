# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "johndoe#{n}@email.pl" }
    sequence(:first_name) { |n| "John#{n}" }
    sequence(:last_name) { |n| "Doe#{n}" }
    sequence(:show_welcome_popup) { |n| false }
    password { "12345678" }
    sequence(:uid) { |n| "uid#{n}" }
    factory :user_with_interests do
      sequence(:scientific_domains) { |n| [create(:scientific_domain)] }
      sequence(:categories) { |n| [create(:category)] }
      sequence(:categories_updates) { true }
      sequence(:scientific_domains_updates) { true }
    end
    factory :user_with_scientific_domains do
      sequence(:scientific_domains) { |n| [create(:scientific_domain)] }
      sequence(:scientific_domains_updates) { true }
    end
    factory :user_with_categories do
      sequence(:categories) { |n| [create(:category)] }
      sequence(:categories_updates) { true }
    end
  end
end
