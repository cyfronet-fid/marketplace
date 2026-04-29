# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Datasource, backend: true do
  let!(:classification) do
    Vocabulary::DatasourceClassification.create!(
      eid: "ds_classification-aggregators",
      name: "Aggregators",
      description: "Aggregators"
    )
  end

  it "returns V6 datasource-specific attributes" do
    payload = {
      "type" => "DataSource",
      "versionControl" => true,
      "datasourceClassification" => "ds_classification-aggregators",
      "researchProductTypes" => %w[ds_research_entity_type-research_data dataset],
      "thematic" => true,
      "accessTypes" => "access_type-remote"
    }

    imported_hash = described_class.call(payload)

    expect(imported_hash).to eq(
      version_control: true,
      datasource_classification: classification,
      research_product_types: %w[ds_research_entity_type-research_data dataset],
      thematic: true
    )
  end

  it "ignores removed V5 datasource structures" do
    payload = {
      "versionControl" => nil,
      "persistentIdentitySystems" => [{ "entityType" => "removed" }],
      "researchEntityTypes" => ["removed"],
      "researchProductLicensings" => ["removed"],
      "researchProductMetadataLicensing" => ["removed"],
      "researchProductAccessPolicies" => ["removed"],
      "researchProductMetadataAccessPolicies" => ["removed"],
      "submissionPolicyURL" => "https://example.org/submission",
      "preservationPolicyURL" => "https://example.org/preservation",
      "harvestable" => true,
      "researchProductTypes" => nil
    }

    imported_hash = described_class.call(payload)

    expect(imported_hash).to eq(
      version_control: false,
      datasource_classification: nil,
      research_product_types: [],
      thematic: false
    )
  end
end
