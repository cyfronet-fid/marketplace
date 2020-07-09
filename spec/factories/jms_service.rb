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
      next {
        "aggregatedServices" => "1",
        "category" => "aggregator",
        "changeLog" => { "changeLog" => [
            "fixed bug"
        ] },
        "datasets"=>"0",
        "multimedia" => [
            "https://www.youtube.com/watch?v=-_F8NZwWXew"
        ],
        "useCases" =>  { "useCase" => [
            "http://phenomenal-h2020.eu/home/help"
        ] },
        "privacyPolicy" => "http://phenomenal-h2020.eu/home/help",
        "description"=> "A catalogue of corpora (datasets) made up of mainly Open Access scholarly publications. Users can view publicly available corpora that have been created with the OpenMinTeD Corpus Builder for Scholarly Works, or manually uploaded to the OpenMinTeD platform.&nbsp; The catalogue can be browsed and searched via the faceted navigation facility or a google-like free text search query. All users can view the descriptions of the corpora (with administrative and technical information, such as language, domain, keywords, licence, resource creator, etc.), as well as the contents and, when available, the metadata descriptions of the individual files that compose them.&nbsp; In addition, registered users can process them with the TDM applications offered by OpenMinTeD and download them in accordance with their licensing conditions.",
        "feedback" => "http://openminted.eu/support/",
        "funding" => "EC funds (H2020 grant 654021 for the OpenMinTeD project) & National funds for the GRNET cloud infrastructure on which the platform operates",
        "fundingBody" => {
          "fundingBody" => [
            "funding_body-fb"
          ]
        },
        "fundingPrograms" => {
          "fundingProgram" => [
            "funding_program-fp"
          ]
        },
        "mainContact" => {
            "firstName" => "John",
            "lastName" => "Doe",
            "email" => "john@doe.com",
            "phone" => "+41 678 888 123",
            "position" => "Developer",
            "organisation" => "JD company"
        },
        "publicContacts" => { "publicContact" => [
            {
                "firstName" => "Jane 1",
                "lastName" => "Doe",
                "email" => "john1@doe.com"
            },
            {
                "firstName" => "Jane 2",
                "lastName" => "Doe",
                "email" => "jane2@doe.com"
            }
        ] },
        "helpdeskPage" => "https://services.openminted.eu/support",
        "id" => eid,
        "languageAvailabilities" => { "languageAvailability"=>"english" },
        "lastUpdate" => "Wed, 05 Sep 2018 00:00:00 +0000".to_date,
        "lifeCycleStatus" => "production",
        "name" => name,
        "options" => "Standard",
        "order" => "http://openminted.eu/omtd-services/catalogue-of-scholarly-datasets/",
        "otherProducts" => "0",
        "geographicalAvailabilities" => { "geographicalAvailability" => "WW" },
        "resourceGeographicLocations" => { "resourceGeographicLocation" => [
            "PL"
        ] },
        "accessModes" => { "accessMode" => [
            "access_mode-am"
        ] },
        "accessTypes" => { "accessType" => [
            "access_type-at"
        ] },
        "certifications" => { "certification" => [
            "ISO-639"
        ] },
        "standards" => { "standard" => [
            "standard"
        ] },
        "openSourceTechnologies" => { "openSourceTechnology" => [
            "opensource"
        ] },
        "grantProjectNames" => { "grantProjectName" => [
            "grant"
        ] },
        "price" => "http://openminted.eu/pricing/",
        "resourceOrganisation" => "tp",
        "resourceProviders" => {
          "resourceProvider" => prov_eid
        },
        "publications" => "0",
        "relatedResources" => {
            "relatedResource" => ["super-service"]
        },
        "requiredResources" => {
            "requiredResource" => ["super-service"]
        },
        "serviceLevelAgreement" => "http://openminted.eu/sla-agreement/",
        "softwareApplications" => "0",
        "subcategory" => "data",
        "symbol" => logo,
        "tagline" => "Find easily accessible corpora of scholarly content and mine them!",
        "tags" => { "tag" => [
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
          ] },
        "targetUsers" => {
          "targetUsers" =>
          ["researchers",
           "risk-assessors"]
        },
        "termsOfUse" => { "termOfUse" => "https://services.openminted.eu/support/termsAndConditions" },
        "trainingInformation" => "http://openminted.eu/support-training/",
        "trl" => "trl-8",
        "url" => "http://openminted.eu/omtd-services/catalogue-of-scholarly-datasets/",
        "userBase" => nil,
        "userManual" => "http://openminted.eu/user-manual/",
        "userValue" =>
          "For users interested in finding corpora of various languages and domains easily accessible and ready to be processed with TDM applications; the use of a uniform metadata schema for their description facilitates comparison and contrast and thereby selection of the appropriate corpus.",
        "version" => "1.0",
        "active" => true,
        "latest" => true
      }
    end
  end
end
