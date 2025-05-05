# frozen_string_literal: true

FactoryBot.define do
  factory :jms_catalogue_response, class: Hash do
    skip_create
    transient do
      eid { "tp" }
      name { "Test Catalogue #{eid}" }
    end
    initialize_with do
      {
        "id" => eid,
        "name" => name,
        "pid" => eid,
        "abbreviation" => "cat",
        "status" => "approved",
        "description" => "test",
        "website" => "https://website.com",
        "inclusionCriteria" => "https://website.com",
        "endOfLife" => "TBD",
        "validationProcess" => "https://website.com",
        "scope" => "test",
        "active" => true,
        "suspended" => false,
        "logo" => "https://www.cyfronet.pl/zalacznik/8437",
        "users" => [{ "email" => "test@mail.pl", "name" => "test", "surname" => "test" }],
        "location" => {
          "streetNameAndNumber" => "street",
          "postalCode" => "00-000",
          "city" => "test",
          "region" => "WW",
          "country" => "N/E"
        },
        "publicContacts" => [{ "email" => "test@mail.pl" }]
      }
    end
  end
end
