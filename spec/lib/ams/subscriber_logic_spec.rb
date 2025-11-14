# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Subscriber do
  let(:subscription) { { destination_prefix: "prefix", name: "test-sub" } }
  let(:subscriber) { Ams::Subscriber.new }

  describe "#build_destination" do
    it "extracts model and action from topic" do
      destination = subscriber.build_destination(subscription, {}, topic: "mp-service-create")
      expect(destination).to eq("prefix.service.create")
    end

    it "handles multi-dash models" do
      destination = subscriber.build_destination(subscription, {}, topic: "mp-interoperability_record-update")
      expect(destination).to eq("prefix.interoperability_record.update")
    end

    it "falls back to attributes if topic is missing" do
      attributes = { "resource" => "provider", "action" => "delete" }
      destination = subscriber.build_destination(subscription, attributes)
      expect(destination).to eq("prefix.provider.delete")
    end

    it "prefers attributes['destination'] if present" do
      attributes = { "destination" => "explicit.dest" }
      destination = subscriber.build_destination(subscription, attributes, topic: "mp-service-create")
      expect(destination).to eq("explicit.dest")
    end
  end

  describe "#acknowledge_messages" do
    let(:url) { "http://ams.example.com/projects/p/subscriptions/s:pull" }
    let(:ack_ids) { %w[id1 id2] }
    let(:subscription) { { token: "secret" } }

    it "sends POST request to :acknowledge endpoint with ackIds" do
      stub_request(:post, "http://ams.example.com/projects/p/subscriptions/s:acknowledge").with(
        body: { ackIds: ack_ids }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "X-Api-Key" => "secret"
        }
      ).to_return(status: 204)

      subscriber.acknowledge_messages(url, ack_ids, subscription)

      expect(WebMock).to have_requested(:post, "http://ams.example.com/projects/p/subscriptions/s:acknowledge").with(
        body: { ackIds: ack_ids }.to_json
      )
    end

    it "skips request if ack_ids is empty" do
      subscriber.acknowledge_messages(url, [], subscription)
      expect(WebMock).not_to have_requested(:post, /:acknowledge/)
    end
  end

  describe "#pull_loop" do
    let(:url) { "http://ams.example.com/projects/p/subscriptions/s" }
    let(:subscription) { { pull_url: url, poll_interval: 0.0001, token: "secret" } }
    let(:messages) { [{ body: "{}", attributes: {}, ack_id: "ack1" }, { body: "{}", attributes: {}, ack_id: "ack2" }] }

    before do
      allow(subscriber).to receive(:pull_messages).and_return(messages, [])
      allow(subscriber).to receive(:handle_ams_message)
      allow(subscriber).to receive(:sleep)
      # Use instance_variable_set to control loop since stop_requested is not a method
      subscriber.instance_variable_set(:@stop_requested, false)
      # We want it to run once and then stop.
      # Since we can't easily mock the loop condition @stop_requested directly with allow
      # because it's an instance variable, we'll mock pull_messages to set it.
      allow(subscriber).to receive(:pull_messages) do
        subscriber.instance_variable_set(:@stop_requested, true)
        messages
      end
    end

    it "calls acknowledge_messages after processing messages" do
      expect(subscriber).to receive(:acknowledge_messages).with(url, %w[ack1 ack2], subscription)
      subscriber.pull_loop(subscription)
    end
  end
end
