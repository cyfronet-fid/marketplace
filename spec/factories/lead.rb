# frozen_string_literal: true

FactoryBot.define do
  factory :lead do
    after(:build) do |help_item|
      help_item.picture.attach(
        io: File.open(Rails.root.join("spec", "factories", "images", "test.png")),
        filename: "test.png",
        content_type: "image/png"
      )
    end
    sequence(:header) { |n| "Lead item #{n}" }
    sequence(:body) { |n| "Lead item #{n}" }
    sequence(:url) { |_n| "https://test.test" }
    sequence(:position) { |_n| 1 }
    lead_section
  end
end
