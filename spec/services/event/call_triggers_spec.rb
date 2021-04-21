# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event::CallTriggers do
  before do
    allow(Oms::CallTriggerJob).to receive(:perform_later)
  end

  it "executes for each returned OMS" do
    oms1 = double
    oms2 = double

    described_class.new(double(omses: [oms1, oms2])).call

    expect(Oms::CallTriggerJob).to have_received(:perform_later).with(oms1)
    expect(Oms::CallTriggerJob).to have_received(:perform_later).with(oms2)
  end

  it "doesn't execute if no OMSes returned" do
    described_class.new(double(omses: [])).call

    expect(Oms::CallTriggerJob).not_to have_received(:perform_later)
  end
end
