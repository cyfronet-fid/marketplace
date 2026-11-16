# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ComponentSchema, :backend do
  describe ".all" do
    subject(:schemas) { described_class.all }

    let(:file_names) { Rails.root.glob("swagger/v1/schemas/*.json").map { |file| file.basename(".json").to_s } }
    let(:referenced_names) { schemas.to_json.scan(%r{#/components/schemas/(\w+)}).flatten.uniq }

    it "has one schema for each file" do
      expect(schemas.keys).to match_array(file_names)
    end

    it "refers only to schemas that are present" do
      expect(schemas.keys).to include(*referenced_names)
    end
  end

  describe "#validate!" do
    subject(:validation) { described_class.new("offer_write").validate!(payload.to_json) }

    context "when the payload agrees with the schema" do
      let(:payload) { { name: "Offer", description: "Description", order_type: "open_access" } }

      it "returns true" do
        expect(validation).to be(true)
      end
    end

    context "when a necessary property is missing" do
      let(:payload) { { name: "Offer", description: "Description" } }

      it "raises a validation error" do
        expect { validation }.to raise_error(JSON::Schema::ValidationError, /order_type/)
      end
    end

    context "when the payload breaks a schema that the schema refers to" do
      let(:parameter) { { id: "1", type: "attribute", value: "value", value_type: "string" } }
      let(:payload) do
        { name: "Offer", description: "Description", order_type: "open_access", parameters: [parameter] }
      end

      it "raises a validation error" do
        expect { validation }.to raise_error(JSON::Schema::ValidationError, /parameters/)
      end
    end

    context "when a nullable property is null" do
      let(:payload) { { name: "Offer", description: "Description", order_type: "open_access", order_url: nil } }

      it "returns true" do
        expect(validation).to be(true)
      end
    end

    context "when a nullable property has the wrong type" do
      let(:payload) { { name: "Offer", description: "Description", order_type: "open_access", order_url: 1 } }

      it "raises a validation error" do
        expect { validation }.to raise_error(JSON::Schema::ValidationError, /order_url/)
      end
    end
  end
end
