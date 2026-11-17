# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::OpenapiBundle, :backend do
  subject(:bundle) { described_class.call(file_fixture("openapi_bundle")) }

  let(:inlined_offer_index) do
    {
      "type" => "array",
      "items" => {
        "allOf" => ["type" => "object", "properties" => { "parameter" => { "type" => "string" } }]
      }
    }
  end

  it "has the paths of all the documents" do
    expect(bundle["paths"].keys).to contain_exactly("/offers", "/search")
  end

  it "has the components of all the documents" do
    expect(bundle["components"].keys).to contain_exactly("securitySchemes", "schemas")
  end

  it "has one description of the API" do
    expect(bundle["info"]).to eq(described_class::INFO)
  end

  it "replaces the references to files with the content of the files" do
    expect(bundle.dig("paths", "/offers", "get", "responses", "200", "schema")).to eq(inlined_offer_index)
  end

  it "keeps the references to the components" do
    expect(bundle.dig("paths", "/search", "get", "responses", "200", "schema")).to eq(
      "$ref" => "#/components/schemas/SearchResponse"
    )
  end
end
