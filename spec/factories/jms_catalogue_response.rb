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
        "active" => true,
        "users" => {
          "user" => {
            "email" => "test@mail.pl",
            "name" => "test",
            "surname" => "test"
          }
        }
      }
    end
  end
end
