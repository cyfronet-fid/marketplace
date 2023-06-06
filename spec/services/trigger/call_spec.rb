# frozen_string_literal: true

require "rails_helper"

RSpec.describe Trigger::Call, backend: true do
  it "executes" do
    allow(Faraday).to receive(:post)

    described_class.new(build(:trigger)).call

    expect(Faraday).to have_received(:post).with("https://example.com")
  end

  it "executes selected method" do
    allow(Faraday).to receive(:get)

    described_class.new(build(:trigger_method_get)).call

    expect(Faraday).to have_received(:get).with("https://example.com")
  end

  it "executes with basic authorization" do
    allow(Faraday).to receive(:post)

    described_class.new(build(:trigger_with_basic_auth)).call

    expect(Faraday).to have_received(:post).with("https://example.com", authorization: "Basic bmFtZToxMjM0MTIzNA==")
  end
end
