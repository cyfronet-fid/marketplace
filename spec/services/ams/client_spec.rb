# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Client, type: :service do
  subject(:client) { described_class.new }

  describe "#pull" do
    let(:pull_url) { "https://ams.example.com/v1/projects/test/subscriptions/#{subscription_name}:pull" }
    let(:subscription_name) { "test-service-create" }

    context "when max_messages is not provided" do
      before do
        stub_request(:post, pull_url)
          .with(body: { "maxMessages" => "10", "returnImmediately" => "true" })
          .to_return(status: 200, body: { "receivedMessages" => [] }.to_json)
      end

      it "defaults to MAX_MESSAGES=10" do
        client.pull(subscription_name)

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
        client.pull(subscription_name, max_messages: 3)

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
        response = client.pull(subscription_name)

        expect(response.status).to eq(404)
      end
    end

    context "when the request returns a 2xx response" do
      before do
        stub_request(:post, pull_url)
          .to_return(status: 200, body: { "receivedMessages" => [] }.to_json)
      end

      it "returns the raw response" do
        response = client.pull(subscription_name)

        expect(response.status).to eq(200)
      end
    end
  end

  describe "#acknowledge" do
    let(:ack_url) { "https://ams.example.com/v1/projects/test/subscriptions/#{subscription_name}:acknowledge" }
    let(:subscription_name) { "test-service-create" }

    context "when ack_ids is provided" do
      let(:ack_ids) { %w[ack-1 ack-2] }

      before do
        stub_request(:post, ack_url)
          .with(body: { "ackIds" => ack_ids })
          .to_return(status: 200, body: "")
      end

      it "returns a response" do
        response = client.acknowledge(subscription_name, ack_ids: ack_ids)
        expect(response.status).to eq(200)
      end

      it "makes a request with ack_ids in the body" do
        client.acknowledge(subscription_name, ack_ids: ack_ids)

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
        response = client.acknowledge(subscription_name, ack_ids: ack_ids)

        expect(response.status).to eq(500)
      end
    end
  end

  describe "#create_subscription" do
    let(:topic_name) { "service-create" }
    let(:subscription_url) { "https://ams.example.com/v1/projects/test/subscriptions/test-#{topic_name}" }
    let(:expected_body) { { "topic" => "projects/test/topics/#{topic_name}", "ackDeadlineSeconds" => 10 } }

    context "when the request returns a 2xx response" do
      before do
        stub_request(:put, subscription_url)
          .with(body: expected_body)
          .to_return(status: 200, body: { "name" => "test-#{topic_name}" }.to_json)
      end

      it "creates a subscription for the given topic" do
        client.create_subscription(topic_name)

        expect(WebMock).to have_requested(:put, subscription_url)
          .with(body: expected_body)
      end

      it "returns the raw response" do
        response = client.create_subscription(topic_name)

        expect(response.status).to eq(200)
      end
    end

    context "when the request returns a non-2xx response" do
      before do
        stub_request(:put, subscription_url)
          .to_return(status: 409, body: { "message" => "already exists" }.to_json)
      end

      it "returns the raw error response without raising" do
        response = client.create_subscription(topic_name)

        expect(response.status).to eq(409)
      end
    end
  end

  describe "#delete_subscription" do
    let(:topic_name) { "service-create" }
    let(:subscription_url) { "https://ams.example.com/v1/projects/test/subscriptions/test-#{topic_name}" }

    context "when the request returns a 2xx response" do
      before do
        stub_request(:delete, subscription_url)
          .to_return(status: 200, body: "")
      end

      it "deletes the subscription for the given topic" do
        client.delete_subscription(topic_name)

        expect(WebMock).to have_requested(:delete, subscription_url)
      end

      it "returns the raw response" do
        response = client.delete_subscription(topic_name)

        expect(response.status).to eq(200)
      end
    end

    context "when the request returns a non-2xx response" do
      before do
        stub_request(:delete, subscription_url)
          .to_return(status: 404, body: { "message" => "not found" }.to_json)
      end

      it "returns the raw error response without raising" do
        response = client.delete_subscription(topic_name)

        expect(response.status).to eq(404)
      end
    end
  end
end
