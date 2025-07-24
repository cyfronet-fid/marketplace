# frozen_string_literal: true

FactoryBot.define do
  factory :jms_service, class: Hash do
    skip_create
    transient do
      eid { "first.service" }
      name { "Title" }
      prov_eid { "new" }
      logo { "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png" }
    end

    initialize_with do
      next(
        {
          "active" => true,
          "suspended" => false,
          "resource" => {
            "metadata" => {
              "modifiedAt" => 1_600_863_105_818,
              "modifiedBy" => "Marta Swiatkowska",
              "registeredAt" => 1_593_444_757_069,
              "registeredBy" => "Marta Swiatkowska"
            }
          },
          "service" => {
            "changeLog" => ["fixed bug"],
            "datasets" => "0",
            "description" =>
              "A catalogue of corpora (datasets) made up of mainly Open Access scholarly publications. Users can view publicly available corpora that have been created with the OpenMinTeD Corpus Builder for Scholarly Works, or manually uploaded to the OpenMinTeD platform.&nbsp; The catalogue can be browsed and searched via the faceted navigation facility or a google-like free text search query. All users can view the descriptions of the corpora (with administrative and technical information, such as language, domain, keywords, licence, resource creator, etc.), as well as the contents and, when available, the metadata descriptions of the individual files that compose them.&nbsp; In addition, registered users can process them with the TDM applications offered by OpenMinTeD and download them in accordance with their licensing conditions.",
            "fundingBody" => ["funding_body-fb"],
            "fundingPrograms" => ["funding_program-fp"],
            "mainContact" => {
              "firstName" => "John",
              "lastName" => "Doe",
              "email" => "john@doe.com",
              "phone" => "+41 678 888 123",
              "position" => "Developer",
              "organisation" => "JD company"
            },
            "publicContacts" => [
              {
                "firstName" => "Jane 1",
                "lastName" => "Doe",
                "email" => "john1@doe.com",
                "phone" => "+41 678 888 123",
                "position" => "Developer",
                "organisation" => "JD company"
              },
              {
                "firstName" => "Jane 2",
                "lastName" => "Doe",
                "email" => "jane2@doe.com",
                "phone" => "+41 678 888 123",
                "position" => "Developer",
                "organisation" => "JD company"
              }
            ],
            "helpdeskPage" => "https://services.openminted.eu/support",
            "id" => eid,
            "languageAvailabilities" => ["en"],
            "lastUpdate" => 1_599_609_600,
            "lifeCycleStatus" => "production",
            "name" => name,
            "order" => "http://openminted.eu/omtd-services/catalogue-of-scholarly-datasets/",
            "geographicalAvailabilities" => ["WW"],
            "grantProjectNames" => ["grant"],
            "pricing" => "http://openminted.eu/pricing/",
            "paymentModel" => "http://openminted.eu/payment-model",
            "resourceOrganisation" => "tp",
            "resourceProviders" => [prov_eid],
            "relatedResources" => ["super-service"],
            "requiredResources" => ["super-service"],
            "serviceLevel" => "http://openminted.eu/sla-agreement/",
            "categories" => [{ "category" => "category-data", "subcategory" => "subcategory-access" }],
            "logo" => logo,
            "scientificDomains" => [
              {
                "scientificDomain" => "scientific_domain-other",
                "scientificSubdomain" => "scientific_subdomain-other-other"
              }
            ],
            "tagline" => "Find easily accessible corpora of scholarly content and mine them!",
            "tags" => [
              "Text Mining",
              "Catalogue",
              "Research",
              "Data Mining",
              "TDM ",
              "Corpora",
              "Datasets",
              "Scholarly literature",
              "Scientific publications",
              "Scholarly content"
            ],
            "targetUsers" => %w[researchers risk-assessors],
            "termsOfUse" => "https://services.openminted.eu/support/termsAndConditions",
            "trainingInformation" => "http://openminted.eu/support-training/",
            "trl" => "trl-8",
            "webpage" => "http://openminted.eu/omtd-services/catalogue-of-scholarly-datasets/",
            "userManual" => "http://openminted.eu/user-manual/",
            "version" => "1.0",
            "accessPolicy" => "http://openminted.eu/pricing/",
            "statusMonitoring" => "http://openminted.eu/monitoring/",
            "maintenance" => "http://openminted.eu/maintenance/",
            "multimedia" => ["https://www.youtube.com/watch?v=-_F8NZwWXew"],
            "useCases" => ["http://phenomenal-h2020.eu/home/help"],
            "accessTypes" => ["access_type-at"],
            "accessModes" => ["access_mode-am"],
            "resourceGeographicLocations" => ["PL"],
            "helpdeskEmail" => "info@bluebridge.support_for_data_publication",
            "securityContactEmail" => "info@bluebridge.support_for_data_publication",
            "certifications" => ["ISO-639"],
            "standards" => ["standard"],
            "openSourceTechnologies" => ["opensource"],
            "privacyPolicy" => "http://phenomenal-h2020.eu/home/help",
            "orderType" => "order_type-other"
          }
        }
      )
    end
  end
end
