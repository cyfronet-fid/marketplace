# frozen_string_literal: true

require "rails_helper"
require_relative "../../../lib/otel_logging/json_formatter"

RSpec.describe OtelLogging::JsonFormatter do
  subject(:entry) { JSON.parse(line) }

  let(:line) { described_class.new(contexts: contexts).call(severity, time, nil, message) }
  let(:contexts) { [] }
  let(:severity) { "INFO" }
  let(:time) { Time.utc(2026, 11, 25, 10, 15, 30, 123_456) }
  let(:message) { "Reindex started" }

  context "with a text message" do
    it "gives the time in UTC with microseconds" do
      expect(entry["timestamp"]).to eq("2026-11-25T10:15:30.123456Z")
    end

    it "gives the severity text" do
      expect(entry["severity_text"]).to eq("INFO")
    end

    it "gives the OpenTelemetry severity number" do
      expect(entry["severity_number"]).to eq(9)
    end

    it "gives the text as the body" do
      expect(entry["body"]).to eq("Reindex started")
    end

    it "gives no other fields" do
      expect(entry.keys).to contain_exactly("timestamp", "severity_text", "severity_number", "body")
    end

    it "ends the entry with one line end" do
      expect(line).to end_with("}\n")
    end
  end

  context "with a text of more than one line" do
    let(:message) { "RuntimeError (boom):\n\napp/models/service.rb:12:in `save'" }

    it "writes one line" do
      expect(line.count("\n")).to eq(1)
    end

    it "keeps the line ends in the body" do
      expect(entry["body"]).to eq(message)
    end
  end

  context "with the DEBUG severity" do
    let(:severity) { "DEBUG" }

    it "gives the severity number 5" do
      expect(entry["severity_number"]).to eq(5)
    end
  end

  context "with the WARN severity" do
    let(:severity) { "WARN" }

    it "gives the severity number 13" do
      expect(entry["severity_number"]).to eq(13)
    end
  end

  context "with the ERROR severity" do
    let(:severity) { "ERROR" }

    it "gives the severity number 17" do
      expect(entry["severity_number"]).to eq(17)
    end
  end

  context "with the FATAL severity" do
    let(:severity) { "FATAL" }

    it "gives the severity number 21" do
      expect(entry["severity_number"]).to eq(21)
    end
  end

  context "with a severity that OpenTelemetry does not know" do
    let(:severity) { "ANY" }

    it "gives the severity text" do
      expect(entry["severity_text"]).to eq("ANY")
    end

    it "gives no severity number" do
      expect(entry).not_to have_key("severity_number")
    end
  end

  context "with contexts" do
    let(:contexts) do
      [{ "service.name" => "web", "mp.variant" => "pl" }, { "request_id" => "0b1f", "trace_id" => nil }]
    end

    it "gives the fields of the first context" do
      expect(entry).to include("service.name" => "web", "mp.variant" => "pl")
    end

    it "gives the fields of the second context" do
      expect(entry).to include("request_id" => "0b1f")
    end

    it "gives no key for a field without a value" do
      expect(entry).not_to have_key("trace_id")
    end

    it "keeps the body" do
      expect(entry["body"]).to eq("Reindex started")
    end
  end

  context "with a hash message" do
    let(:message) { { "body" => "GET /services 200", "http.response.status_code" => 200, duration_ms: 41.37 } }

    it "gives the keys of the hash as fields" do
      expect(entry).to include("body" => "GET /services 200", "http.response.status_code" => 200)
    end

    it "gives a symbol key as a text key" do
      expect(entry).to include("duration_ms" => 41.37)
    end
  end

  context "with an exception message" do
    let(:message) { RuntimeError.new("boom").tap { |error| error.set_backtrace(%w[service.rb:12 offer.rb:7]) } }

    it "gives the message of the exception as the body" do
      expect(entry["body"]).to eq("boom")
    end

    it "gives the class of the exception" do
      expect(entry["exception.type"]).to eq("RuntimeError")
    end

    it "gives the message of the exception" do
      expect(entry["exception.message"]).to eq("boom")
    end

    it "gives the backtrace as one text" do
      expect(entry["exception.stacktrace"]).to eq("service.rb:12\noffer.rb:7")
    end
  end

  context "with an exception without a backtrace" do
    let(:message) { RuntimeError.new("boom") }

    it "gives no stack trace" do
      expect(entry).not_to have_key("exception.stacktrace")
    end
  end

  context "with a message that is not a text" do
    let(:message) { [:reindex, 3] }

    it "gives the inspected value as the body" do
      expect(entry["body"]).to eq("[:reindex, 3]")
    end
  end

  context "with a text that is not valid UTF-8" do
    let(:message) { "caf\xE9" }

    it "replaces the invalid bytes" do
      expect(entry["body"]).to eq("caf�")
    end
  end

  context "with a binary text" do
    let(:message) { "caf\xE9".b }

    it "replaces the bytes that are not ASCII" do
      expect(entry["body"]).to eq("caf�")
    end
  end

  context "with a hash that JSON cannot write" do
    let(:message) { { "url.path" => "/caf\xE9" } }

    it "gives the inspected hash as the body" do
      expect(entry["body"]).to include("url.path", "/caf\\xE9")
    end
  end

  describe "#entry" do
    subject(:entry_text) { described_class.new(contexts: contexts).entry(severity, time, message) }

    it "gives the entry without the line end" do
      expect(entry_text).not_to include("\n")
    end

    it "gives the same fields as #call" do
      expect(JSON.parse(entry_text)).to eq(entry)
    end
  end
end
