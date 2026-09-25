# frozen_string_literal: true

require "rails_helper"

RSpec.describe SuspendJob, :backend do
  let(:service) { build_stubbed(:service) }

  before do
    allow(Service::Suspend).to receive(:call)
    described_class.perform_now(service)
  end

  it "runs the Suspend operation of the object's class" do
    expect(Service::Suspend).to have_received(:call).with(service)
  end
end
