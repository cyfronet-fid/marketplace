# frozen_string_literal: true

FactoryBot.define do
  factory :jms_providers_response, class: Hash do
    skip_create
    initialize_with do
      # noinspection RubyStringKeysInHashInspection
      next(
        {
          "total" => 2,
          "from" => 0,
          "to" => 2,
          "results" => [
            {
              "id" => "bluebridge",
              "name" => "BlueBRIDGE",
              "website" => "https://www.bluebridge-vres.eu/",
              "catalogueOfResources" => nil,
              "publicDescOfResources" => nil,
              "logo" => "https://about.west-life.eu/network/west-life/about/templates/westlife/images/west-life.png",
              "additionalInfo" => "-",
              "contactInformation" => nil,
              "active" => true,
              "status" => "approved",
              "abbreviation" => "BlueBRIDGE",
              "description" => "test",
              "location" => {
                "streetNameAndNumber" => "street",
                "postalCode" => "00-000",
                "city" => "test",
                "region" => "WW",
                "country" => "N/E"
              },
              "publicContacts" => {
                "publicContact" => [{ "email" => "test@mail.pl" }]
              },
              "users" => {
                "user" => [{ "email" => "test@mail.pl", "name" => "test", "surname" => "test" }]
              }
            },
            {
              "id" => "phenomenal",
              "name" => "Phenomenal",
              "website" => "http://phenomenal-h2020.eu/home/",
              "catalogueOfResources" => nil,
              "publicDescOfResources" => nil,
              "logo" => "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png",
              "additionalInfo" => "-",
              "contactInformation" => "",
              "active" => true,
              "status" => "approved",
              "abbreviation" => "Phenomenal",
              "description" => "test",
              "location" => {
                "streetNameAndNumber" => "street",
                "postalCode" => "00-000",
                "city" => "test",
                "region" => "WW",
                "country" => "N/E"
              },
              "publicContacts" => {
                "publicContact" => [{ "email" => "test@mail.pl" }]
              },
              "users" => {
                "user" => [{ "email" => "test@mail.pl", "name" => "test", "surname" => "test" }]
              }
            },
            {
              "id" => "West-Life",
              "name" => "World-wide E-infrastructure for structural biology",
              "website" => "https://west-life.eu",
              "catalogueOfResources" => "https://bio.tools/",
              "publicDescOfResources" => "https://about.west-life.eu/network/west-life/services",
              "logo" => "https://about.west-life.eu/network/west-life/about/templates/westlife/images/west-life.png",
              "additionalInfo" =>
                "https://about.west-life.eu/network/west-life/about/project. For more information contact chris.morris@stfc.ac.uk",
              "contactInformation" => "+44 1925 603689",
              "active" => true,
              "status" => "approved",
              "abbreviation" => "West-Life",
              "description" => "test",
              "location" => {
                "streetNameAndNumber" => "street",
                "postalCode" => "00-000",
                "city" => "test",
                "region" => "WW",
                "country" => "N/E"
              },
              "publicContacts" => {
                "publicContact" => [{ "email" => "test@mail.pl" }]
              },
              "users" => {
                "user" => [{ "email" => "test@mail.pl", "name" => "test", "surname" => "test" }]
              }
            },
            {
              "id" => "awesome",
              "name" => "Awesome provider",
              "website" => "https://www.osom-prov.eu/",
              "catalogueOfResources" => nil,
              "publicDescOfResources" => nil,
              "logo" => "https://about.west-life.eu/network/west-life/about/templates/westlife/images/west-life.png",
              "additionalInfo" => "Nothing, cause I'm avesome",
              "contactInformation" => nil,
              "active" => true,
              "status" => "approved",
              "abbreviation" => "Awesome provider",
              "description" => "test",
              "location" => {
                "streetNameAndNumber" => "street",
                "postalCode" => "00-000",
                "city" => "test",
                "region" => "WW",
                "country" => "N/E"
              },
              "publicContacts" => {
                "publicContact" => [{ "email" => "test@mail.pl" }]
              },
              "users" => {
                "user" => [{ "email" => "test@mail.pl", "name" => "test", "surname" => "test" }]
              }
            }
          ],
          "facets" => [
            {
              "field" => "resourceType",
              "label" => "Resource Type",
              "values" => [{ "value" => "provider", "label" => nil, "count" => 21 }]
            }
          ]
        }
      )
    end
  end
  factory :jms_published_provider_response, class: Hash do
    skip_create
    transient do
      eid { "tp" }
      name { "Test Provider #{eid}" }
    end
    initialize_with do
      {
        "id" => eid,
        "name" => name,
        "website" => "http://beta.providers.eosc-portal.eu",
        "catalogueOfResources" => "http://no.i.dont",
        "publicDescOfResources" => "http://no.i.dont",
        "logo" => "https://cdn.shopify.com/s/files/1/0553/3925/products/logo_developers_grande.png?v=1432756867",
        "additionalInfo" => "no",
        "contactInformation" => "test phone number",
        "active" => true,
        "status" => "approved",
        "abbreviation" => "test",
        "description" => "test",
        "location" => {
          "streetNameAndNumber" => "street",
          "postalCode" => "00-000",
          "city" => "test",
          "region" => "WW",
          "country" => "N/E"
        },
        "mainContact" => {
          "firstName" => "Test",
          "lastName" => "Provider",
          "email" => "test@mail.pl"
        },
        "publicContacts" => {
          "publicContact" => {
            "email" => "test@mail.pl"
          }
        },
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
  factory :jms_draft_provider_response, class: Hash do
    skip_create
    transient do
      eid { "tp" }
      name { "Test Provider #{eid}" }
    end
    initialize_with do
      {
        "id" => eid,
        "name" => name,
        "website" => "http://beta.providers.eosc-portal.eu",
        "catalogueOfResources" => "http://no.i.dont",
        "publicDescOfResources" => "http://no.i.dont",
        "logo" => "https://cdn.shopify.com/s/files/1/0553/3925/products/logo_developers_grande.png?v=1432756867",
        "additionalInfo" => "no",
        "contactInformation" => "test phone number",
        "active" => false,
        "status" => "approved",
        "abbreviation" => "test",
        "description" => "test",
        "location" => {
          "streetNameAndNumber" => "street",
          "postalCode" => "00-000",
          "city" => "test",
          "region" => "WW",
          "country" => "N/E"
        },
        "mainContact" => {
          "firstName" => "Test",
          "lastName" => "Provider",
          "email" => "test@mail.pl"
        },
        "publicContacts" => {
          "publicContact" => {
            "email" => "test@mail.pl"
          }
        },
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
