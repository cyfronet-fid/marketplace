# frozen_string_literal: true

FactoryBot.define do
  factory :link_use_cases_url, class: Link::UseCasesUrl do
    sequence(:name) { |n| "Use case #{n}" }
    sequence(:url) { "http://example.org" }
  end
end
