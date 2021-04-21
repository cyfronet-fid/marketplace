# frozen_string_literal: true

require "rails_helper"

RSpec.describe Oms::CallTriggerJob, type: :job do
  let(:call_trigger) { instance_double(Oms::CallTrigger) }
  let(:oms) { build(:oms) }

  before do
    allow(Oms::CallTrigger).to receive(:new).with(oms).and_return(call_trigger)
    allow(call_trigger).to receive(:call)
  end

  it "triggers service" do
    described_class.perform_now(oms)
    expect(call_trigger).to have_received(:call)
  end
end
