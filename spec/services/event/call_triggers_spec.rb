# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event::CallTriggers, backend: true do
  before { allow(OMS::CallTriggerJob).to receive(:perform_later) }

  it "executes for each returned OMS" do
    oms1 = double
    oms2 = double

    described_class.new(double(omses: [oms1, oms2])).call

    expect(OMS::CallTriggerJob).to have_received(:perform_later).with(oms1)
    expect(OMS::CallTriggerJob).to have_received(:perform_later).with(oms2)
  end

  it "doesn't execute if no OMSes returned" do
    described_class.new(double(omses: [])).call

    expect(OMS::CallTriggerJob).not_to have_received(:perform_later)
  end
end
