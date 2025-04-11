# frozen_string_literal: true

MP_VERSION = ENV["MP_VERSION"] || File.read(Rails.root.join("VERSION")).strip

# time after which user can rate service that starts when service become ready
# default value is set to 90 days, ENV variable should represent number of days
RATE_AFTER_PERIOD = ENV["RATE_AFTER_PERIOD"].present? ? ENV["RATE_AFTER_PERIOD"].to_i.days : 90.days

VOCABULARY_TYPES = {
  target_user: {
    name: "Target User",
    klass: "TargetUser",
    route: :target_users
  },
  access_mode: {
    name: "Access Mode",
    klass: "Vocabulary::AccessMode",
    route: :access_modes
  },
  access_type: {
    name: "Access Type",
    klass: "Vocabulary::AccessType",
    route: :access_types
  },
  funding_body: {
    name: "Funding Body",
    klass: "Vocabulary::FundingBody",
    route: :funding_bodies
  },
  funding_program: {
    name: "Funding Program",
    klass: "Vocabulary::FundingProgram",
    route: :funding_programs
  },
  trl: {
    name: "TRL",
    klass: "Vocabulary::Trl",
    route: :trls
  },
  life_cycle_status: {
    name: "Life Cycle Status",
    klass: "Vocabulary::LifeCycleStatus",
    route: :life_cycle_statuses
  },
  provider_life_cycle_status: {
    name: "Provider Life Cycle Status",
    klass: "Vocabulary::ProviderLifeCycleStatus",
    route: :provider_life_cycle_statuses
  },
  area_of_activity: {
    name: "Area of Activity",
    klass: "Vocabulary::AreaOfActivity",
    route: :areas_of_activity
  },
  hosting_legal_entity: {
    name: "Hosting Legal Entity",
    klass: "Vocabulary::HostingLegalEntity",
    route: :hosting_legal_entities
  },
  esfri_domain: {
    name: "ESFRI Domain",
    klass: "Vocabulary::EsfriDomain",
    route: :esfri_domains
  },
  esfri_type: {
    name: "ESFRI Type",
    klass: "Vocabulary::EsfriType",
    route: :esfri_types
  },
  legal_status: {
    name: "Legal Status",
    klass: "Vocabulary::LegalStatus",
    route: :legal_statuses
  },
  network: {
    name: "Network",
    klass: "Vocabulary::Network",
    route: :networks
  },
  societal_grand_challenge: {
    name: "Societal Grand Challenge",
    klass: "Vocabulary::SocietalGrandChallenge",
    route: :societal_grand_challenges
  },
  structure_type: {
    name: "Structure Type",
    klass: "Vocabulary::StructureType",
    route: :structure_types
  },
  meril_scientific_domain: {
    name: "MERIL Scientific Domain",
    klass: "Vocabulary::MerilScientificDomain",
    route: :meril_scientific_domains
  },
  research_activity: {
    name: "Research Activity",
    klass: "Vocabulary::ResearchActivity",
    route: :research_activities
  },
  jurisdiction: {
    name: "Jurisdiction",
    klass: "Vocabulary::Jurisdiction",
    route: :jurisdictions
  },
  datasource_classification: {
    name: "Datasource Classification",
    klass: "Vocabulary::DatasourceClassification",
    route: :datasource_classifications
  },
  entity_type: {
    name: "Entity Type",
    klass: "Vocabulary::EntityType",
    route: :entity_types
  },
  entity_type_scheme: {
    name: "Entity Type Scheme",
    klass: "Vocabulary::EntityTypeScheme",
    route: :entity_type_schemes
  },
  product_access_policy: {
    name: "Product Access Policy",
    klass: "Vocabulary::ResearchProductAccessPolicy",
    route: :product_access_policies
  },
  service_category: {
    name: "Service Category",
    klass: "Vocabulary::ServiceCategory",
    route: :service_categories
  },
  bundle_goal: {
    name: "Bundle Goal",
    klass: "Vocabulary::BundleGoal",
    route: :bundle_goals
  },
  bundle_capability_of_goal: {
    name: "Bundle Capability of Goal",
    klass: "Vocabulary::BundleCapabilityOfGoal",
    route: :bundle_capabilities_of_goal
  }
}.freeze

