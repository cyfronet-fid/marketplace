# frozen_string_literal: true

require "rails_helper"

RSpec.describe Parameter::Select, backend: true do
  context "with string value type" do
    subject { build(:select_parameter) }

    it "serializes to attribute schema" do
      expect(Attribute.from_json(subject.dump)).to be_config_valid
    end

    it "serializes to valid attribute attribute" do
      attribute = Attribute.from_json(subject.dump)
      attribute.value_from_param(["b"])

      expect(attribute).to be_value_valid
    end
  end

  context "with integer value type" do
    subject { build(:select_parameter, value_type: "integer", values: [1, 2, 3]) }

    it "serializes to attribute schema" do
      expect(Attribute.from_json(subject.dump)).to be_config_valid
    end

    it "serializes to valid attribute attribute" do
      attribute = Attribute.from_json(subject.dump)
      attribute.value_from_param(["2"])

      expect(attribute).to be_value_valid
    end
  end

  context "with numerical string value type" do
    subject { build(:select_parameter, value_type: "string", values: %w[1 2 3 >4]) }

    it "sertializes to attribute schema" do
      expect(Attribute.from_json(subject.dump)).to be_config_valid
    end

    it "serializes to valid attribute attribute" do
      attribute = Attribute.from_json(subject.dump)
      attribute.value_from_param(["2"])

      expect(attribute).to be_value_valid
    end
  end
end
