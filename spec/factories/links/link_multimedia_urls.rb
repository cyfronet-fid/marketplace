# frozen_string_literal: true

FactoryBot.define do
  factory :link_multimedia_url, class: Link::MultimediaUrl do
    sequence(:name) { |n| "Multimedia #{n}" }
    sequence(:url) { "http://example.org" }
  end
end
