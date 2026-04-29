# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::DatasourcePolicy, backend: true do
  let(:coordinator) { create(:user, roles: [:coordinator]) }

  it "permits only the V6 datasource-specific attributes" do
    attrs = described_class.new(coordinator, build(:datasource)).permitted_attributes

    expect(attrs).to include(:version_control, :thematic, :jurisdiction_id, :datasource_classification_id)
    expect(attrs).to include([research_product_types: []])
    expect(attrs).not_to include(
      :submission_policy_url,
      :preservation_policy_url,
      :harvestable,
      [research_entity_type_ids: []],
      [research_product_access_policy_ids: []],
      [research_product_metadata_access_policy_ids: []]
    )
  end
end
