# frozen_string_literal: true

FactoryBot.define do
  factory :eosc_registry_vocabularies_response, class: Hash do
    skip_create
    initialize_with do
      # noinspection RubyStringKeysInHashInspection
      next(
        {
          "PROVIDER_SOCIETAL_GRAND_CHALLENGE" => [
            {
              "id" => "provider_societal_grand_challenge-energy",
              "name" => "Energy",
              "description" => "Secure, clean and efficient energy.",
              "parentId" => nil,
              "type" => "Provider societal grand challenge",
              "extras" => {
              }
            }
          ],
          "PROVIDER_ESFRI_TYPE" => [
            {
              "id" => "provider_esfri_type-landmark",
              "name" => "Landmark",
              "description" => "RI is an ESFRI landmark",
              "parentId" => nil,
              "type" => "Provider esfri type",
              "extras" => {
              }
            }
          ],
          "PROVIDER_LIFE_CYCLE_STATUS" => [
            {
              "id" => "provider_life_cycle_status-being_upgraded",
              "name" => "Being Upgraded",
              "description" => "The Research Infrastructure is currently being upgraded.",
              "parentId" => nil,
              "type" => "Provider life cycle status",
              "extras" => {
              }
            }
          ],
          "LIFE_CYCLE_STATUS" => [
            {
              "id" => "life_cycle_status-alpha",
              "name" => "Alpha",
              "description" => "Resource prototype available for closed set of users",
              "parentId" => nil,
              "type" => "Life cycle status",
              "extras" => {
              }
            }
          ],
          "SCIENTIFIC_SUBDOMAIN" => [
            {
              "id" => "scientific_subdomain-agricultural_sciences-agricultural_biotechnology",
              "name" => "Agricultural Biotechnology",
              "description" => nil,
              "parentId" => "scientific_domain-agricultural_sciences",
              "type" => "Scientific subdomain",
              "extras" => {
              }
            }
          ],
          "PROVIDER_MERIL_SCIENTIFIC_SUBDOMAIN" => [
            {
              "id" =>
                "provider_meril_scientific_subdomain-biological_and_medical_sciences-agronomy_forestry_plant_breeding_centres",
              "name" => "Agronomy, Forestry, Plant Breeding Centres",
              "description" => "Facilities that enable open field and forest experiments",
              "parentId" => "provider_meril_scientific_domain-biological_and_medical_sciences",
              "type" => "Provider meril scientific subdomain",
              "extras" => {
              }
            }
          ],
          "FUNDING_BODY" => [
            {
              "id" => "funding_body-ademe",
              "name" => "Agency for Environment and Energy Management (ADEME)",
              "description" => "France",
              "parentId" => nil,
              "type" => "Funding body",
              "extras" => {
              }
            }
          ],
          "TARGET_USER" => [
            {
              "id" => "target_user-businesses",
              "name" => "Businesses",
              "description" => "An organization or economic system where goods and services are exchanged.",
              "parentId" => nil,
              "type" => "Target user",
              "extras" => {
              }
            }
          ],
          "PROVIDER_MERIL_SCIENTIFIC_DOMAIN" => [
            {
              "id" => "provider_meril_scientific_domain-biological_and_medical_sciences",
              "name" => "Biological & Medical Sciences",
              "description" => nil,
              "parentId" => nil,
              "type" => "Provider meril scientific domain",
              "extras" => {
              }
            }
          ],
          "PROVIDER_STATE" => [
            {
              "id" => "approved",
              "name" => "Approved Provider",
              "description" => "Approved Provider",
              "parentId" => nil,
              "type" => "Provider state",
              "extras" => {
              }
            }
          ],
          "COUNTRY" => [
            {
              "id" => "AD",
              "name" => "Andorra",
              "description" => nil,
              "parentId" => nil,
              "type" => "Country",
              "extras" => {
              }
            }
          ],
          "FUNDING_PROGRAM" => [
            {
              "id" => "funding_program-afis2020",
              "name" => "Anti Fraud Information System (AFIS2020)",
              "description" => nil,
              "parentId" => nil,
              "type" => "Funding program",
              "extras" => {
              }
            }
          ],
          "PROVIDER_AREA_OF_ACTIVITY" => [
            {
              "id" => "provider_area_of_activity-applied_research",
              "name" => "Applied Research",
              "description" => nil,
              "parentId" => nil,
              "type" => "Provider area of activity",
              "extras" => {
              }
            }
          ],
          "CATEGORY" => [
            {
              "id" => "category-access_physical_and_eInfrastructures-compute",
              "name" => "Compute",
              "description" =>
                "High-performance computing resources and scalable cloud compute capacity for demanding job processes.",
              "parentId" => "supercategory-access_physical_and_eInfrastructures",
              "type" => "Category",
              "extras" => {
                icon: "ic_compute.svg",
                icon_active: "ic_compute_active.svg"
              }
            }
          ],
          "SUBCATEGORY" => [
            {
              "id" => "subcategory-access_physical_and_eInfrastructures-compute-container_management",
              "name" => "Container Management",
              "description" => nil,
              "parentId" => "category-access_physical_and_eInfrastructures-compute",
              "type" => "Subcategory",
              "extras" => {
              }
            }
          ],
          "SCIENTIFIC_DOMAIN" => [
            {
              "id" => "scientific_domain-agricultural_sciences",
              "name" => "Agricultural Sciences",
              "description" => "Sciences dealing with food and fibre production and processing.",
              "parentId" => nil,
              "type" => "Scientific domain",
              "extras" => {
                icon: "ic_analytics.svg",
                icon_active: "ic_analytics_active.svg"
              }
            }
          ],
          "TRL" => [
            {
              "id" => "trl-1",
              "name" => "1 - basic principles observed",
              "description" => "Scientific research has led to observation and reports.",
              "parentId" => nil,
              "type" => "Technology readiness level",
              "extras" => {
              }
            }
          ],
          "PROVIDER_LEGAL_STATUS" => [
            {
              "id" => "provider_legal_status-association",
              "name" => "Association",
              "description" => nil,
              "parentId" => nil,
              "type" => "Provider legal status",
              "extras" => {
              }
            }
          ],
          "PROVIDER_NETWORK" => [
            {
              "id" => "provider_network-4c",
              "name" => "Collaboration to Clarify the Costs of Curation (4C)",
              "description" => nil,
              "parentId" => nil,
              "type" => "Provider network",
              "extras" => {
              }
            }
          ],
          "ACCESS_MODE" => [
            {
              "id" => "access_mode-free",
              "name" => "Free",
              "description" => "Users can freely access the Resource provided, registration may be needed.",
              "parentId" => nil,
              "type" => "Access mode",
              "extras" => {
              }
            }
          ],
          "LANGUAGE" => [
            {
              "id" => "aa",
              "name" => "Afar",
              "description" => nil,
              "parentId" => nil,
              "type" => "Language",
              "extras" => {
              }
            }
          ],
          "PROVIDER_ESFRI_DOMAIN" => [
            {
              "id" => "provider_esfri_domain-data_computing_and_digital_research_infrastructures",
              "name" => "Data, Computing & Digital Research Infrastructures",
              "description" =>
                "In research, as in all fields of society, Information and Communications Technology (ICT) has become a key enabling factor for progress.",
              "parentId" => nil,
              "type" => "Provider esfri domain",
              "extras" => {
              }
            }
          ],
          "SUPERCATEGORY" => [
            {
              "id" => "supercategory-access_physical_and_eInfrastructures",
              "name" => "Access physical & eInfrastructures",
              "description" =>
                "Ultra-fast connectivity and ubiquitous access, high performance computing, cloud capacity and storage.",
              "parentId" => nil,
              "type" => "Supercategory",
              "extras" => {
                icon: "ic_security.svg",
                icon_active: "ic_security_active.svg"
              }
            }
          ],
          "ORDER_TYPE" => [
            {
              "id" => "order_type-fully_open_access",
              "name" => "Fully Open Access",
              "description" =>
                "No ordering procedure necessary to access the resource and no user authentication required.",
              "parentId" => nil,
              "type" => "Order type",
              "extras" => {
              }
            }
          ],
          "PROVIDER_STRUCTURE_TYPE" => [
            {
              "id" => "provider_structure_type-distributed",
              "name" => "Distributed",
              "description" =>
                "The Provider has multiple physical locations but a unified management structure and a single coordination centre.",
              "parentId" => nil,
              "type" => "Provider structure type",
              "extras" => {
              }
            }
          ],
          "ACCESS_TYPE" => [
            {
              "id" => "access_type-mail_in",
              "name" => "Mail-In",
              "description" => "Samples are sent in to for e.g. analysis and the results are returned I.",
              "parentId" => nil,
              "type" => "Access type",
              "extras" => {
              }
            }
          ]
        }
      )
    end
  end
end
