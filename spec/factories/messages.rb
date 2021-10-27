# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    sequence(:message) { |n| "text message #{n}" }
    sequence(:author) { |_n| create(:user) }
    author_role { "user" }
    scope { "public" }
    sequence(:messageable) { association(:project_item) }
    sequence(:edited) { false }
    sequence(:iid) { |_n| "n" }

    factory :provider_message do
      sequence(:author) { nil }
      author_role { "provider" }
      author_name { |n| "provider #{n}" }
      author_email { |n| "provider#{n}@provider.pl" }
    end
  end
end
