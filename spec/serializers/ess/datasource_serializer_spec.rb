# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ess::DatasourceSerializer, backend: true do
  it "serializes the V6 datasource-specific surface" do
    classification =
      Vocabulary::DatasourceClassification.create!(
        eid: "ds_classification-aggregators",
        name: "Aggregators",
        description: "Aggregators"
      )
    jurisdiction = create(:vocabulary_jurisdiction, eid: "ds_jurisdiction-global", name: "Global")
    datasource =
      create(
        :datasource,
        version_control: true,
        thematic: true,
        datasource_classification: classification,
        jurisdiction: jurisdiction,
        research_product_types: ["ds_research_entity_type-research_data"]
      )

    data = described_class.new(datasource).as_json

    expect(data).to include(
      version_control: true,
      thematic: true,
      datasource_classification: "Aggregators",
      jurisdiction: "Global",
      research_product_types: ["ds_research_entity_type-research_data"]
    )
    expect(data.keys).not_to include(
      :persistent_identity_systems,
      :research_entity_types,
      :research_product_access_policies,
      :research_product_metadata_access_policies,
      :research_product_licensing_urls,
      :research_product_metadata_license_urls,
      :submission_policy_url,
      :preservation_policy_url
    )
  end
end
