# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::JsonSchema, :backend do
  subject(:json_schema) { described_class.new(schema).to_h }

  context "when the schema has no nullable keyword" do
    let(:schema) { { "type" => "object", "properties" => { "name" => { "type" => "string" } } } }

    it "returns the same schema" do
      expect(json_schema).to eq(schema)
    end
  end

  context "when a property is nullable" do
    let(:schema) { { "type" => "object", "properties" => { "unit" => { "type" => "string", "nullable" => true } } } }

    it "changes the property into a oneOf with the null type" do
      expect(json_schema.dig("properties", "unit")).to eq("oneOf" => [{ "type" => "string" }, { "type" => "null" }])
    end
  end

  context "when a nullable schema is in an array" do
    let(:schema) { { "oneOf" => [{ "type" => "integer", "nullable" => true }, { "type" => "boolean" }] } }

    it "changes the schema in the array" do
      expect(json_schema["oneOf"].first).to eq("oneOf" => [{ "type" => "integer" }, { "type" => "null" }])
    end
  end

  context "when a property has the name nullable" do
    let(:schema) { { "type" => "object", "properties" => { "nullable" => { "type" => "boolean" } } } }

    it "keeps the property" do
      expect(json_schema).to eq(schema)
    end
  end

  context "when nullable is false" do
    let(:schema) { { "type" => "string", "nullable" => false } }

    it "returns the same schema" do
      expect(json_schema).to eq(schema)
    end
  end
end
