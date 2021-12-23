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
      sequence(:author_name) { |n| "provider #{n}" }
      sequence(:author_email) { |n| "provider#{n}@provider.pl" }
    end

    factory :mediator_message do
      sequence(:author) { nil }
      author_role { "mediator" }
      sequence(:author_name) { |n| "customer service #{n}" }
      sequence(:author_email) { |n| "cs#{n}@customer.service.pl" }
    end
  end
end
