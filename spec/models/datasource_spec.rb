# frozen_string_literal: true

require "rails_helper"

RSpec.describe Datasource, backend: true do
  it "uses the Service model name for STI forms" do
    expect(described_class.model_name).to eq(Service.model_name)
    expect(described_class.type).to eq("Datasource")
  end

  it "keeps research product types as plain strings" do
    datasource = build(:datasource, research_product_types: ["ds_research_entity_type-research_data"])

    expect(datasource.research_product_types).to eq(["ds_research_entity_type-research_data"])
  end
end
