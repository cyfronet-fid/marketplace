# frozen_string_literal: true

FactoryBot.define do
  factory :offer do
    sequence(:name) { |n| "offer #{n}" }
    sequence(:description) { |n| "offer #{n} description" }
    sequence(:service) { |n| create(:service, offers_count: 1) }
    sequence(:status) { :published }

    factory :offer_with_parameters do
      sequence(:parameters) { [{ "id": "id1",
                                "type": "input",
                                "label": "Test input",
                                "value_type": "string",
                                "description": "Write sth"
                              }] }
    end
  end
end
