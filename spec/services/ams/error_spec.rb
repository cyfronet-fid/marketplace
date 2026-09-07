# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Error do
  subject(:error) { described_class.new("something went wrong") }

  it "is a StandardError" do
    expect(error).to be_a(StandardError)
  end

  it "prefixes the message with [AMS]" do
    expect(error.message).to eq("[AMS] something went wrong")
  end
end
