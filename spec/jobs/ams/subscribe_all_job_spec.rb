# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::SubscribeAllJob, type: :job do
  describe "#perform_now" do
    before do
      allow(Ams::SubscribeJob).to receive(:perform_later)
    end

    it "calls Ams::SubscribeJob once per topic" do
      described_class.perform_now
      expect(Ams::SubscribeJob).to have_received(:perform_later).twice
    end

    it "calls Ams::SubscribeJob for the first subscription" do
      described_class.perform_now
      expect(Ams::SubscribeJob).to have_received(:perform_later).with("test-service-create")
    end

    it "calls Ams::SubscribeJob for the second subscription" do
      described_class.perform_now
      expect(Ams::SubscribeJob).to have_received(:perform_later).with("test-service-update")
    end
  end

  it "enqueues on the ams_subscriber queue" do
    ActiveJob::Base.queue_adapter = :test
    expect { described_class.perform_later }.to have_enqueued_job.on_queue("ams_subscriber")
  end
end
