# frozen_string_literal: true

require "rails_helper"

RSpec.describe Parameter::Input, backend: true do
  subject { build(:input_parameter) }

  it "serializes to attribute schema" do
    expect(Attribute.from_json(subject.dump)).to be_config_valid
  end

  it "serializes to valid attribute attribute" do
    attribute = Attribute.from_json(subject.dump)
    attribute.value_from_param("input value")

    expect(attribute).to be_value_valid
  end
end
