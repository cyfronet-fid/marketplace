# frozen_string_literal: true

require "rails_helper"

describe "AMS rake tasks", type: :task do
  describe "ams:create_subscriptions" do
    let(:task_name) { "ams:create_subscriptions" }
    let(:dry_run) { false }

    let(:response) { instance_double(Faraday::Response, status: 200) }
    let(:client) { instance_double(Ams::Client, create_subscription: response) }

    before do
      task.reenable

      allow(Ams::Client).to receive(:new).and_return(client)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("DRY_RUN", false).and_return(dry_run)
    end

    it "preloads the Rails environment" do
      expect(task.prerequisites).to include "environment"
    end

    it "creates a subscription for each configured topic" do
      task.invoke
      expect(client).to have_received(:create_subscription).with("service-create")
    end

    context "when DRY_RUN is true" do
      let(:dry_run) { true }

      it "does not create any subscriptions" do
        task.invoke
        expect(client).not_to have_received(:create_subscription)
      end
    end

    context "when subscription_prefix is not configured" do
      before do
        config = Rails.application.config_for(:ams)

        allow(config).to receive(:subscription_prefix).and_return("")
        allow(Rails.application).to receive(:config_for).with(:ams).and_return(config)
      end

      it "does not create any subscriptions" do
        task.invoke
        expect(client).not_to have_received(:create_subscription)
      end
    end
  end

  describe "ams:delete_subscriptions" do
    let(:task_name) { "ams:delete_subscriptions" }
    let(:dry_run) { false }

    let(:response) { instance_double(Faraday::Response, status: 200) }
    let(:client) { instance_double(Ams::Client, delete_subscription: response) }

    before do
      task.reenable

      allow(Ams::Client).to receive(:new).and_return(client)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("DRY_RUN", false).and_return(dry_run)
    end

    it "preloads the Rails environment" do
      expect(task.prerequisites).to include "environment"
    end

    it "deletes a subscription for each configured topic" do
      task.invoke
      expect(client).to have_received(:delete_subscription).with("service-create")
    end

    context "when DRY_RUN is true" do
      let(:dry_run) { true }

      it "does not delete any subscriptions" do
        task.invoke
        expect(client).not_to have_received(:delete_subscription)
      end
    end

    context "when subscription_prefix is not configured" do
      before do
        config = Rails.application.config_for(:ams)

        allow(config).to receive(:subscription_prefix).and_return("")
        allow(Rails.application).to receive(:config_for).with(:ams).and_return(config)
      end

      it "does not delete any subscriptions" do
        task.invoke
        expect(client).not_to have_received(:delete_subscription)
      end
    end
  end
end
