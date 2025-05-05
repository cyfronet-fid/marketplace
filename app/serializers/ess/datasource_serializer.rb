# frozen_string_literal: true

class Ess::DatasourceSerializer < Ess::ServiceSerializer
  attribute :thematic, if: :datasource?
  attribute :research_product_access_policies, if: :datasource?
  attribute :research_product_metadata_access_policies, if: :datasource?
  attribute :research_entity_types, if: :datasource?
  attribute :datasource_classification, if: :datasource?
  attribute :persistent_identity_systems, if: :datasource?
  attribute :jurisdiction, if: :datasource?
  attribute :research_product_license_urls, key: :research_product_licensing_urls, if: :datasource?
  attribute :research_product_metadata_license_urls, if: :datasource?
  attribute :submission_policy_url, if: :datasource?
  attribute :preservation_policy_url, if: :datasource?
  attribute :version_control, if: :datasource?
  attribute :node
end
