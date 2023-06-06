# frozen_string_literal: true

require "rails_helper"

RSpec.describe Parameter::Constant, backend: true do
  subject { build(:input_parameter) }

  it "serializes to attribute schema" do
    expect(Attribute.from_json(subject.dump)).to be_config_valid
  end
end
