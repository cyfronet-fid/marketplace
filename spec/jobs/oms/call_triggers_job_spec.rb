# frozen_string_literal: true

require "rails_helper"

RSpec.describe OMS::CallTriggerJob, type: :job, backend: true do
  let(:call_trigger) { instance_double(Trigger::Call) }
  let(:oms) { build(:oms) }

  before do
    allow(Trigger::Call).to receive(:new).with(oms.trigger).and_return(call_trigger)
    allow(call_trigger).to receive(:call)
  end

  context "for OMS with trigger" do
    let(:oms) { build(:oms_with_trigger) }

    it "calls service" do
      described_class.perform_now(oms)
      expect(call_trigger).to have_received(:call)
    end
  end

  context "for OMS without trigger" do
    it "doesn't call service" do
      described_class.perform_now(oms)
      expect(call_trigger).not_to have_received(:call)
    end
  end
end
