# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    sequence(:message) { |n| "text message #{n}" }
    sequence(:author) { |n| create(:user) }
    author_role { "user" }
    scope { "public" }
    sequence(:messageable) { association(:project_item) }
    sequence(:edited) { false }
    sequence(:iid) { |n| "n" }
  end
end
