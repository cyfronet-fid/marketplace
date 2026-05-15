# frozen_string_literal: true

class Ess::DatasourceSerializer < Ess::ServiceSerializer
  attributes :version_control, :thematic, :datasource_classification, :jurisdiction, :research_product_types
  attribute :node
end
