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
      sequence(:research_areas) { |n| [create(:research_area)] }
      sequence(:categories) { |n| [create(:category)] }
      sequence(:categories_updates) { true }
      sequence(:research_areas_updates) { true }
    end
    factory :user_with_research_areas do
      sequence(:research_areas) { |n| [create(:research_area)] }
      sequence(:research_areas_updates) { true }
    end
    factory :user_with_categories do
      sequence(:categories) { |n| [create(:category)] }
      sequence(:categories_updates) { true }
    end
  end
end
