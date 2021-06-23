# frozen_string_literal: true

require "rails_helper"

RSpec.describe Trigger::Call do
  it "executes" do
    allow(Unirest).to receive(:post)

    described_class.new(build(:trigger)).call

    expect(Unirest).to have_received(:post).with("https://example.com")
  end

  it "executes selected method" do
    allow(Unirest).to receive(:get)

    described_class.new(build(:trigger_method_get)).call

    expect(Unirest).to have_received(:get).with("https://example.com")
  end
end
