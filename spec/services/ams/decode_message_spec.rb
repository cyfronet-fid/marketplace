# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::DecodeMessage do
  subject(:decode_message) { described_class.call(message) }

  describe "#call" do
    context "when the message has the real AMS envelope (base64-encoded JSON nested under 'message.data')" do
      let(:payload) { { "id" => "123" } }
      let(:message) do
        { "ackId" => "ack-1", "message" => { "data" => Base64.strict_encode64(payload.to_json) } }
      end

      it "adds the parsed payload as a top-level 'data' key, keeping the original envelope" do
        expect(decode_message).to eq(
          "ackId" => "ack-1",
          "message" => message["message"],
          "data" => payload
        )
      end
    end

    context "when the message has base64-encoded JSON directly in a top-level 'data' key" do
      let(:payload) { { "id" => "123" } }
      let(:message) { { "ackId" => "ack-1", "data" => Base64.strict_encode64(payload.to_json) } }

      it "replaces data with the parsed payload" do
        expect(decode_message).to eq("ackId" => "ack-1", "data" => payload)
      end
    end

    context "when the message has base64-encoded JSON in 'body' instead of 'data'" do
      let(:payload) { { "id" => "456" } }
      let(:message) { { "ackId" => "ack-2", "body" => Base64.strict_encode64(payload.to_json) } }

      it "sets data to the parsed payload" do
        expect(decode_message).to eq("ackId" => "ack-2", "body" => message["body"], "data" => payload)
      end
    end

    context "when the decoded value is not valid JSON" do
      let(:message) { { "ackId" => "ack-3", "data" => Base64.strict_encode64("not json") } }

      it "returns the original message unchanged" do
        expect(decode_message).to eq(message)
      end

      it "logs the failure" do
        allow(Ams::Logger).to receive(:error)
        decode_message
        expect(Ams::Logger).to have_received(:error).with(/Failed to decode AMS message/)
      end
    end

    context "when 'message.data', 'data' and 'body' are all blank" do
      let(:message) { { "ackId" => "ack-4" } }

      it "returns the original message unchanged" do
        expect(decode_message).to eq(message)
      end
    end

    context "when decoding succeeds" do
      let(:message) { { "message" => { "data" => Base64.strict_encode64({ "id" => "1" }.to_json) } } }

      it "does not mutate the original message hash" do
        decode_message
        expect(message).not_to have_key("data")
      end
    end
  end
end
