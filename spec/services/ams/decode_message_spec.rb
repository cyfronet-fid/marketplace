# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::DecodeMessage do
  subject(:decode_message) { described_class.call(message) }

  describe "#call" do
    context "when the message has base64-encoded JSON in a top-level 'data' key" do
      let(:payload) { { "id" => "123" } }
      let(:message) { { "data" => Base64.strict_encode64(payload.to_json) } }

      it "replaces data with the parsed payload" do
        expect(decode_message).to eq("data" => payload)
      end
    end

    context "when the message has base64-encoded JSON in 'body' instead of 'data'" do
      let(:payload) { { "id" => "456" } }
      let(:message) { { "body" => Base64.strict_encode64(payload.to_json) } }

      it "sets data to the parsed payload" do
        expect(decode_message).to eq("body" => message["body"], "data" => payload)
      end
    end

    context "when the decoded value is not valid JSON" do
      let(:message) { { "data" => Base64.strict_encode64("not json") } }

      it "returns the original message unchanged" do
        expect(decode_message).to eq(message)
      end

      it "logs the failure" do
        allow(Ams::Logger).to receive(:error)
        decode_message
        expect(Ams::Logger).to have_received(:error).with(/Failed to decode AMS message/)
      end
    end

    context "when 'data' and 'body' are both blank" do
      let(:message) { { "foo" => "bar" } }

      it "returns the original message unchanged" do
        expect(decode_message).to eq(message)
      end
    end

    context "when decoding succeeds" do
      let(:encoded) { Base64.strict_encode64({ "id" => "1" }.to_json) }
      let(:message) { { "data" => encoded } }

      it "does not mutate the original message hash" do
        decode_message
        expect(message["data"]).to eq(encoded)
      end
    end
  end
end
