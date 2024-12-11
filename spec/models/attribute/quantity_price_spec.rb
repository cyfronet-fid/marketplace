# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attribute::QuantityPrice, backend: true do
  let(:price) do
    Attribute.from_json(
      {
        "id" => "id6",
        "label" => "Label",
        "description" => "Description",
        "type" => "quantity_price",
        "value_type" => "integer",
        "config" => {
          "start_price" => 100,
          "step_price" => 1,
          "currency" => "EUR",
          "max" => 3
        }
      }
    )
  end

  context "max validation" do
    it "is ok for lower than max" do
      price.value = 2

      expect(price).to be_valid
    end

    it "is invalid for greater than max" do
      price.value = 4

      expect(price).to_not be_valid
    end
  end

  context "min validation" do
    it "is invalid for lower than 0" do
      price.value = -1

      expect(price).to_not be_valid
    end
  end

  def attr_json_with_config(config)
    {
      "id" => "id6",
      "label" => "Start of service",
      "description" => "Please choose start date",
      "type" => "date",
      "value_type" => "string",
      "config" => config
    }
  end
end
