# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Subscribe do
  subject(:subscribe) { described_class.call(subscription_name) }

  let(:subscription_name) { "test-service-create" }
  let(:pull_url) { "https://ams.example.com/v1/projects/test/subscriptions/#{subscription_name}:pull" }
  let(:ack_url) { "https://ams.example.com/v1/projects/test/subscriptions/#{subscription_name}:acknowledge" }

  before { stub_request(:post, ack_url) }

  describe "#call" do
    context "when there are messages to process" do
      let(:raw_message) { { "ackId" => "ack-1", "message" => { "data" => "encoded" } } }
      let(:decoded_message) { { "data" => { "foo" => "bar" } } }

      before do
        stub_request(:post, pull_url).to_return(
          body: { "receivedMessages" => [raw_message] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

        allow(Ams::DecodeMessage).to receive(:call).with(raw_message["message"]).and_return(decoded_message)
      end

      it "passes the decoded message to Ams::ProcessMessage" do
        allow(Ams::ProcessMessage).to receive(:call).and_return(true)
        subscribe
        expect(Ams::ProcessMessage).to have_received(:call).with(subscription_name, message: decoded_message)
      end

      it "acknowledges successfully processed messages" do
        allow(Ams::ProcessMessage).to receive(:call).and_return(true)
        subscribe
        expect(WebMock).to have_requested(:post, ack_url).with(body: { "ackIds" => ["ack-1"] })
      end

      it "does not acknowledge messages that failed processing" do
        allow(Ams::ProcessMessage).to receive(:call).and_return(false)
        subscribe
        expect(WebMock).not_to have_requested(:post, ack_url)
      end
    end

    context "when there are no messages" do
      before do
        stub_request(:post, pull_url).to_return(
          body: { "receivedMessages" => [] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "does not acknowledge" do
        subscribe
        expect(WebMock).not_to have_requested(:post, ack_url)
      end
    end

    context "when receivedMessages is absent from the response" do
      before do
        stub_request(:post, pull_url).to_return(
          body: {}.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "does not acknowledge" do
        subscribe
        expect(WebMock).not_to have_requested(:post, ack_url)
      end
    end

    context "when the pull request fails" do
      before { stub_request(:post, pull_url).to_return(status: 500, body: { "message" => "boom" }.to_json) }

      it "raises instead of silently treating it as no messages" do
        expect { subscribe }.to raise_error(/AMS pull failed for #{subscription_name}: 500/)
      end
    end

    context "when the acknowledge request fails" do
      let(:raw_message) { { "ackId" => "ack-1", "message" => { "data" => "encoded" } } }

      before do
        stub_request(:post, pull_url).to_return(
          body: { "receivedMessages" => [raw_message] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

        stub_request(:post, ack_url).to_return(status: 500)

        allow(Ams::DecodeMessage).to receive(:call).and_return({})
        allow(Ams::ProcessMessage).to receive(:call).and_return(true)
      end

      it "raises instead of silently swallowing the failure" do
        expect { subscribe }.to raise_error(/AMS acknowledge failed for #{subscription_name}: 500/)
      end
    end
  end
end
