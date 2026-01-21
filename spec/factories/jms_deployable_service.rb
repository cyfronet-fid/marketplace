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
          "url" => "https://test.example.com",
          "node" => "node-sandbox",
          "version" => "1.0.0",
          "softwareLicense" => "MIT",
          "resourceOrganisation" => provider_eid,
          "catalogueId" => nil,
          "creators" => ["Test Creator"],
          "tags" => %w[test deployable],
          "scientificDomains" => [],
          "lastUpdate" => "2024-01-01"
        }
      )
    end
  end
end
