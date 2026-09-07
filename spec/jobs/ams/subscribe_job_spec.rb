# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::SubscribeJob do
  it "delegates to Ams::Subscribe" do
    allow(Ams::Subscribe).to receive(:call)

    described_class.perform_now("test-service-create")
    expect(Ams::Subscribe).to have_received(:call).with("test-service-create")
  end

  it "enqueues on the ams_subscriber queue" do
    ActiveJob::Base.queue_adapter = :test
    expect { described_class.perform_later("test_service-create") }.to have_enqueued_job.on_queue("ams_subscriber")
  end
end
