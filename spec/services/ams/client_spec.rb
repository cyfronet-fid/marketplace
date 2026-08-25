# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Client, type: :service do
  subject(:client) { described_class.new }

  describe "#pull" do
    let(:subscription_path) { "/v1/projects/test/subscriptions/sample" }
    let(:pull_url) { "https://ams.example.com#{subscription_path}:pull" }

    context "when max_messages is not provided" do
      before do
        stub_request(:post, pull_url)
          .with(body: { "maxMessages" => "10", "returnImmediately" => "true" })
          .to_return(status: 200, body: { "receivedMessages" => [] }.to_json)
      end

      it "defaults to MAX_MESSAGES=10" do
        client.pull(subscription_path)

        expect(WebMock).to have_requested(:post, pull_url)
          .with(body: { "maxMessages" => "10", "returnImmediately" => "true" })
      end
    end

    context "when max_messages is provided" do
      before do
        stub_request(:post, pull_url)
          .with(body: { "maxMessages" => "3", "returnImmediately" => "true" })
          .to_return(status: 200, body: { "receivedMessages" => [] }.to_json)
      end

      it "sends the requested batch size" do
        client.pull(subscription_path, max_messages: 3)

        expect(WebMock).to have_requested(:post, pull_url)
          .with(body: { "maxMessages" => "3", "returnImmediately" => "true" })
      end
    end

    context "when the request returns a non-2xx response" do
      before do
        stub_request(:post, pull_url)
          .to_return(status: 404, body: { "message" => "not found" }.to_json)
      end

      it "returns the raw error response without raising" do
        response = client.pull(subscription_path)

        expect(response.status).to eq(404)
      end
    end

    context "when the request returns a 2xx response" do
      before do
        stub_request(:post, pull_url)
          .to_return(status: 200, body: { "receivedMessages" => [] }.to_json)
      end

      it "returns the raw response" do
        response = client.pull(subscription_path)

        expect(response.status).to eq(200)
      end
    end
  end

  describe "#acknowledge" do
    let(:subscription_path) { "/v1/projects/test/subscriptions/sample" }
    let(:ack_url) { "https://ams.example.com#{subscription_path}:acknowledge" }

    context "when ack_ids is not provided" do
      it "returns nil" do
        result = client.acknowledge(subscription_path)
        expect(result).to be_nil
      end

      it "does not make a request" do
        client.acknowledge(subscription_path)
        expect(WebMock).not_to have_requested(:post, ack_url)
      end
    end

    context "when ack_ids is empty" do
      let(:ack_ids) { [] }

      it "returns nil" do
        result = client.acknowledge(subscription_path, ack_ids: ack_ids)
        expect(result).to be_nil
      end

      it "does not make a request" do
        client.acknowledge(subscription_path, ack_ids: ack_ids)
        expect(WebMock).not_to have_requested(:post, ack_url)
      end
    end

    context "when ack_ids is provided" do
      let(:ack_ids) { %w[ack-1 ack-2] }

      before do
        stub_request(:post, ack_url)
          .with(body: { "ackIds" => ack_ids })
          .to_return(status: 200, body: "")
      end

      it "returns a response" do
        response = client.acknowledge(subscription_path, ack_ids: ack_ids)
        expect(response.status).to eq(200)
      end

      it "makes a request with ack_ids in the body" do
        client.acknowledge(subscription_path, ack_ids: ack_ids)

        expect(WebMock).to have_requested(:post, ack_url)
          .with(body: { "ackIds" => ack_ids })
      end
    end

    context "when the request returns a non-2xx response" do
      let(:ack_ids) { %w[ack-1 ack-2] }

      before do
        stub_request(:post, ack_url)
          .to_return(status: 500, body: "boom")
      end

      it "returns the raw error response without raising" do
        response = client.acknowledge(subscription_path, ack_ids: ack_ids)

        expect(response.status).to eq(500)
      end
    end
  end
end
