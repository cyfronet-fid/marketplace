# frozen_string_literal: true

MP_VERSION = ENV["MP_VERSION"] || File.read(Rails.root.join("VERSION")).strip

# time after which user can rate service that starts when service become ready
# default value is set to 90 days, ENV variable should represent number of days
RATE_AFTER_PERIOD = ENV["RATE_AFTER_PERIOD"].present? ? ENV["RATE_AFTER_PERIOD"].to_i.days : 90.days

VOCABULARY_TYPES = {
  access_type: {
    name: "Access Type",
    klass: "Vocabulary::AccessType",
    route: :access_types
  },
  bundle_capability_of_goal: {
    name: "Bundle Capability of Goal",
    klass: "Vocabulary::BundleCapabilityOfGoal",
    route: :bundle_capabilities_of_goal
  },
  bundle_goal: {
    name: "Bundle Goal",
    klass: "Vocabulary::BundleGoal",
    route: :bundle_goals
  },
  datasource_classification: {
    name: "Datasource Classification",
    klass: "Vocabulary::DatasourceClassification",
    route: :datasource_classifications
  },
  hosting_legal_entity: {
    name: "Hosting Legal Entity",
    klass: "Vocabulary::HostingLegalEntity",
    route: :hosting_legal_entities
  },
  jurisdiction: {
    name: "Jurisdiction",
    klass: "Vocabulary::Jurisdiction",
    route: :jurisdictions
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
  node: {
    name: "Node",
    klass: "Vocabulary::Node",
    route: :nodes
  },
  trl: {
    name: "TRL",
    klass: "Vocabulary::Trl",
    route: :trls
  }
}.freeze
