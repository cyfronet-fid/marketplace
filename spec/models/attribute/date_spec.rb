# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attribute::Date, backend: true do
  context "min validation" do
    let(:date_attribute) { Attribute.from_json(attr_json_with_config("min" => "now")) }

    it "is ok for current day" do
      date_attribute.value = I18n.l(Date.today)

      expect(date_attribute).to be_valid
    end

    it "is ok for tomorrow" do
      date_attribute.value = I18n.l(Date.today + 1.day)

      expect(date_attribute).to be_valid
    end

    it "is invalid for yesterday" do
      date_attribute.value = I18n.l(Date.today - 1.day)

      expect(date_attribute).to_not be_valid
      expect(date_attribute.errors[:id][0]).to start_with("Please select date after")
    end
  end

  context "min validation" do
    let(:date_attribute) { Attribute.from_json(attr_json_with_config("max" => "now")) }

    it "is ok for current day" do
      date_attribute.value = I18n.l(Date.today)

      expect(date_attribute).to be_valid
    end

    it "is ok for yesterday" do
      date_attribute.value = I18n.l(Date.today - 1.day)

      expect(date_attribute).to be_valid
    end

    it "is invalid for tomorrow" do
      date_attribute.value = I18n.l(Date.today + 1.day)

      expect(date_attribute).to_not be_valid
      expect(date_attribute.errors[:id][0]).to start_with("Please select date before")
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
