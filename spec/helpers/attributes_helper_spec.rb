# frozen_string_literal: true

require "rails_helper"

RSpec.describe AttributesHelper, type: :helper, backend: true do
  context "parse_offer_parameter_value" do
    it "should display value" do
      expect(
        parse_offer_parameter_value(
          "id" => "id2",
          "type" => "attribute",
          "label" => "Number of CPU Cores",
          "value" => 8,
          "value_type" => "integer",
          "description" => "For GPU instance number of CPU cores is constant"
        )
      ).to have_content("8")
    end
    it "should display range" do
      expect(
        parse_offer_parameter_value(
          "id" => "cpu_cores",
          "type" => "select",
          "label" => "Number of CPU Cores",
          "config" => {
            "mode" => "buttons",
            "values" => [8, 12, 16, 20, 24, 28, 32, 64]
          },
          "value_type" => "integer",
          "description" => "Select number of cores you want"
        )
      ).to have_content("8 - 64")
    end
    it "should display options" do
      expect(
        parse_offer_parameter_value(
          "id" => "id2",
          "type" => "select",
          "unit" => "GB",
          "label" => "Amount of RAM per CPU core",
          "config" => {
            "mode" => "buttons",
            "values" => [1, 2, 4]
          },
          "value_type" => "integer",
          "description" => "Select amount of RAM per core"
        )
      ).to have_content("1 - 4 GB")
    end
  end
end
