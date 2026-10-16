# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "johndoe#{n}@email.pl" }
    sequence(:first_name) { |n| "John#{n}" }
    sequence(:last_name) { |n| "Doe#{n}" }
    sequence(:show_welcome_popup) { |_n| false }
    password { "12345678" }
    sequence(:uid) { |n| "uid#{n}" }

    # pl reads User#uid from the primary login identity (pl-marketplace's factory builds one).
    # Built through the has_one so the unsaved user already answers #uid.
    after(:build) do |user|
      if Mp::Variant.pl? && user[:uid].present? && user.primary_identity.nil?
        user.build_primary_identity(provider: "checkin", uid: user[:uid], primary: true)
      end
    end

    factory :user_with_interests do
      sequence(:scientific_domains) { |_n| [create(:scientific_domain)] }
      sequence(:categories) { |_n| [create(:category)] }
      sequence(:categories_updates) { true }
      sequence(:scientific_domains_updates) { true }
    end
    factory :user_with_scientific_domains do
      sequence(:scientific_domains) { |_n| [create(:scientific_domain)] }
      sequence(:scientific_domains_updates) { true }
    end
    factory :user_with_categories do
      sequence(:categories) { |_n| [create(:category)] }
      sequence(:categories_updates) { true }
    end
    factory :user_with_services do
      sequence(:owned_services) { |_n| [create(:service)] }
    end
    factory :user_with_favourites do
      sequence(:favourite_services) { |_n| [create(:service)] }
    end

    factory :user_with_token do
      sequence(:authentication_token) { |n| "token_#{n}" }
    end
    factory :user_with_empty_token do
      authentication_token { "  " }
    end
  end
end
