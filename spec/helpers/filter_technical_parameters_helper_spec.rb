# frozen_string_literal: true

require "rails_helper"

RSpec.describe FilterTechnicalParametersHelper, type: :helper do
  it "should filter out date fields" do
    # noinspection RubyStringKeysInHashInspection
    expect(filter_technical_parameters([{ "type" => "date" }])).to be_empty
  end
  it "should filter out string fields" do
    # noinspection RubyStringKeysInHashInspection
    expect(filter_technical_parameters([{ "value_type" => "string" }])).to be_empty
  end
  it "should pick select objects objects" do
    # noinspection RubyStringKeysInHashInspection
    expect(filter_technical_parameters([{ "id" => "cpu_cores",
                                         "type" => "select",
                                         "label" => "Number of CPU Cores",
                                         "config" => { "mode" => "buttons",
                                                      "values" => [8, 12, 16, 20, 24, 28, 32, 64] },
                                         "value_type" => "integer",
                                         "description" => "Select number of cores you want" }])).to_not be_empty
  end
end
