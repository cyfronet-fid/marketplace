# frozen_string_literal: true

FactoryBot.define do
  factory :jms_deployable_service, class: Hash do
    skip_create
    transient do
      eid { "deployable.service.1" }
      name { "Test Deployable Service" }
      provider_eid { "test.provider" }
    end

    initialize_with do
      next(
        {
          "id" => eid,
          "name" => name,
          "acronym" => "TDS",
          "description" => "A test deployable service for testing purposes",
          "tagline" => "Test tagline",
          "urls" => ["https://test.example.com"],
          "nodePID" => "node-sandbox",
          "version" => "1.0.0",
          "license" => {
            "name" => "MIT",
            "url" => "https://licenses.example.com/mit"
          },
          "resourceOwner" => provider_eid,
          "publishingDate" => "2026-04-15",
          "type" => "DeployableApplication",
          "publicContacts" => ["ops@example.com"],
          "creators" => ["Test Creator"],
          "tags" => %w[test deployable],
          "scientificDomains" => [],
          "lastUpdate" => "2024-01-01"
        }
      )
    end
  end
end
