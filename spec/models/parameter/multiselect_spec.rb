# frozen_string_literal: true

require "rails_helper"

RSpec.describe Parameter::Multiselect, backend: true do
  context "with string value type" do
    subject { build(:multiselect_parameter) }

    it "serializes to attribute schema" do
      expect(Attribute.from_json(subject.dump)).to be_config_valid
    end

    it "serializes to valid attribute attribute" do
      attribute = Attribute.from_json(subject.dump)
      attribute.value_from_param(%w[a b])

      expect(attribute).to be_value_valid
    end
  end

  context "with integer value type" do
    subject { build(:multiselect_parameter, value_type: "integer", values: [1, 2, 3]) }

    it "serializes to attribute schema" do
      expect(Attribute.from_json(subject.dump)).to be_config_valid
    end

    it "serializes to valid attribute attribute" do
      attribute = Attribute.from_json(subject.dump)
      attribute.value_from_param(%w[1 2])

      expect(attribute).to be_value_valid
    end
  end
end
