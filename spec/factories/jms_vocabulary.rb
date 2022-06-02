# frozen_string_literal: true

FactoryBot.define do
  factory :jms_vocabulary, class: Hash do
    skip_create
    transient do
      eid { "target_user-researchers" }
      name { "#{eid.split("-")[1].humanize}" }
    end
    initialize_with do
      {
        "metadata" => {
          "registeredBy" => "John Doe",
          "registeredAt" => "1549033448415",
          "modifiedBy" => "John Doe",
          "modifiedAt" => "1549624107536",
          "source" => "EOSC",
          "originalId" => nil
        },
        "active" => true,
        "vocabulary" => {
          "id" => eid,
          "name" => name,
          "type" => "Target user",
          "description" => "Test"
        }
      }
    end
  end
end
