# frozen_string_literal: true

require "rails_helper"
require_relative "../../../lib/otel_logging/job_context"

RSpec.describe OtelLogging::JobContext do
  let(:job_context) { described_class.new }

  context "without a job" do
    subject(:fields) { job_context.to_h }

    it { is_expected.to eq({}) }
  end

  context "with a job that runs" do
    subject(:fields) { Sidekiq::Context.with(sidekiq_context) { job_context.to_h } }

    let(:sidekiq_context) { { jid: "b4a577edbccf1d805744efa9", class: "Ess::UpdateJob", queue: "ess_update" } }

    it "gives sidekiq as the messaging system" do
      expect(fields["messaging.system"]).to eq("sidekiq")
    end

    it "gives the job id as the message id" do
      expect(fields["messaging.message.id"]).to eq("b4a577edbccf1d805744efa9")
    end

    it "gives the queue as the destination" do
      expect(fields["messaging.destination.name"]).to eq("ess_update")
    end

    it "gives the class of the job" do
      expect(fields["messaging.sidekiq.job_class"]).to eq("Ess::UpdateJob")
    end

    it "gives no duration" do
      expect(fields).not_to have_key("duration_ms")
    end
  end

  context "with a job that is done" do
    subject(:fields) { Sidekiq::Context.with(sidekiq_context) { job_context.to_h } }

    let(:sidekiq_context) do
      { jid: "b4a577edbccf1d805744efa9", class: "Ess::UpdateJob", queue: "ess_update", elapsed: 1.234 }
    end

    it "gives the elapsed seconds of Sidekiq as milliseconds" do
      expect(fields["duration_ms"]).to eq(1234)
    end
  end

  context "with a Sidekiq context that has no job id" do
    subject(:fields) { Sidekiq::Context.with(sidekiq_context) { job_context.to_h } }

    let(:sidekiq_context) { { context: "Exception during Sidekiq lifecycle event" } }

    it { is_expected.to eq({}) }
  end
end
