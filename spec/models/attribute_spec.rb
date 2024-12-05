# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attribute, backend: true do
  it "creates correct string select with value from json" do
    attr =
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "select",
          "value_type" => "string",
          "value" => "b",
          "config" => {
            "values" => %w[a b c]
          }
        }
      )
    expect(attr.config_valid?).to be true
    expect(attr.value_valid?).to be true
  end

  it "sets value of correct select from request param" do
    attr =
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "select",
          "value_type" => "string",
          "config" => {
            "values" => %w[a b c]
          }
        }
      )
    attr.value_from_param(["a"])
  end

  it "creates correct non changable attribute with unit from string" do
    attr =
      Attribute.from_json(
        {
          "id" => "id7",
          "label" => "Attribute non changable",
          "type" => "attribute",
          "unit" => "GB",
          "value_type" => "string",
          "value" => "Value"
        }
      )
    expect(attr.value_valid?).to be true
  end

  # TODO: - known issue for now. Rails auto-coerces to numeric types. Bring this test back once fixed
  # it "creates attribute number string assigned to string" do
  #   attr = Attribute.from_json({
  #                                  "id" => "id7",
  #                                  "label" => "Attribute non changable",
  #                                  "type" => "attribute",
  #                                  "unit" => "GB",
  #                                  "value_type" => "string",
  #                                  "value" => "17",
  #                              })
  #   expect(attr.value_valid?).to be true
  # end

  it "fails on wrong value type" do
    attr =
      Attribute.from_json(
        { "id" => "id1", "label" => "Attribute 1", "type" => "attribute", "value_type" => "integer", "value" => 1 }
      )
    expect(attr.value_valid?).to be true
  end

  it "creates correct date property from json" do
    attr =
      Attribute.from_json(
        { "id" => "id1", "label" => "Attribute 1", "type" => "date", "value_type" => "string", "value" => "10/23/2018" }
      )
    expect(attr.value_valid?).to be true
  end

  it "fails on invalid attribute type" do
    expect do
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "select",
          "value_type" => "fail",
          "value" => "b",
          "config" => {
            "values" => %w[a b c]
          }
        }
      )
    end.to raise_exception(JSON::Schema::ValidationError)
  end

  it "creates correct integer select with value from json" do
    attr =
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "select",
          "value_type" => "integer",
          "value" => 1,
          "config" => {
            "values" => [1, 2, 3]
          }
        }
      )
    expect(attr.config_valid?).to be true
    expect(attr.value_valid?).to be true
  end

  it "creates correct integer multiselectselect with value from json" do
    attr =
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "multiselect",
          "value_type" => "integer",
          "value" => [1, 2, 3],
          "config" => {
            "values" => [1, 2, 3]
          }
        }
      )
    expect(attr.config_valid?).to be true
    expect(attr.value_valid?).to be true
  end

  it "does anything" do
    attr =
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "multiselect",
          "value_type" => "string",
          "value" => %w[1 2],
          "config" => {
            "values" => %w[1 2 3]
          }
        }
      )
    expect(attr.config_valid?).to be true
    expect(attr.value_valid?).to be true
  end

  it "creates correct range property from json" do
    attr =
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "range-property",
          "value_type" => "string",
          "value" => {
            "minimum" => "1312",
            "maximum" => "312312"
          }
        }
      )
    expect(attr.value_valid?).to be true
  end

  it "creates correct number range with value from json" do
    attr =
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "range",
          "value_type" => "integer",
          "value" => 1,
          "config" => {
            "minimum" => 1,
            "maximum" => 100
          }
        }
      )
    expect(attr.value_valid?).to be true
  end

  it "creates correct number range with invalid value from json" do
    expect do
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "range",
          "value_type" => "number",
          "value" => 0,
          "config" => {
            "minimum" => 1,
            "maximum" => 100,
            "exclusiveMinimum" => true
          }
        }
      )
    end.to raise_exception(JSON::Schema::ValidationError)
  end

  it "integer attribute should not raise when created with non integer value [,], should not validate" do
    expect(
      Attribute.from_json(
        { "id" => "id1", "label" => "Attribute 1", "type" => "input", "value_type" => "integer", "value" => "13,2" }
      ).value_valid?
    ).to be_falsey
  end

  it "integer attribute should not raise when created with non integer value [.], should not validate" do
    expect(
      Attribute.from_json(
        { "id" => "id1", "label" => "Attribute 1", "type" => "input", "value_type" => "integer", "value" => "13.2" }
      ).value_valid?
    ).to be_falsey
  end

  it "range attribute should not raise when created with non integer value [,], should not validate" do
    expect(
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "range",
          "value_type" => "integer",
          "value" => "13,2",
          "config" => {
            "minimum" => 1,
            "maximum" => 100,
            "exclusiveMinimum" => true
          }
        }
      ).value_valid?
    ).to be_falsey
  end

  it "range attribute should not raise when created with non integer value [.], should not validate" do
    expect(
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "range",
          "value_type" => "integer",
          "value" => "13.2",
          "config" => {
            "minimum" => 1,
            "maximum" => 100,
            "exclusiveMinimum" => true
          }
        }
      ).value_valid?
    ).to be_falsey
  end

  it "select attribute should not raise when created with non integer value [,], should not validate" do
    attr =
      Attribute.from_json(
        {
          "id" => "id1",
          "label" => "Attribute 1",
          "type" => "select",
          "value_type" => "string",
          "value" => "1,2",
          "config" => {
            "values" => [1, 2, 3]
          }
        }
      )
    expect(attr.value_valid?).to be_falsey
  end

  it "fails to create dummy attribute" do
    expect { Attribute.from_json({ "id" => "id1" }) }.to raise_exception(JSON::Schema::ValidationError)
  end

  # TODO: test individual attribute types in their respective specs
  # TODO much more testing
end
