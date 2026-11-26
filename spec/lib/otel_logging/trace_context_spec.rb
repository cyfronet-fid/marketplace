# frozen_string_literal: true

require "rails_helper"
require_relative "../../../lib/otel_logging/trace_context"

RSpec.describe OtelLogging::TraceContext do
  let(:trace_context) { described_class.new }

  context "without an active span" do
    subject(:fields) { trace_context.to_h }

    it { is_expected.to eq({}) }
  end

  context "with an active sampled span" do
    subject(:fields) { OpenTelemetry::Trace.with_span(span) { trace_context.to_h } }

    let(:span) { OpenTelemetry::Trace.non_recording_span(span_context) }
    let(:span_context) do
      OpenTelemetry::Trace::SpanContext.new(
        trace_id: ["0af7651916cd43dd8448eb211c80319c"].pack("H*"),
        span_id: ["b7ad6b7169203331"].pack("H*"),
        trace_flags: OpenTelemetry::Trace::TraceFlags::SAMPLED
      )
    end

    it "gives the trace id as hex text" do
      expect(fields["trace_id"]).to eq("0af7651916cd43dd8448eb211c80319c")
    end

    it "gives the span id as hex text" do
      expect(fields["span_id"]).to eq("b7ad6b7169203331")
    end

    it "gives the sampled trace flags" do
      expect(fields["trace_flags"]).to eq("01")
    end
  end

  context "with an active span that is not sampled" do
    subject(:fields) { OpenTelemetry::Trace.with_span(span) { trace_context.to_h } }

    let(:span) { OpenTelemetry::Trace.non_recording_span(span_context) }
    let(:span_context) do
      OpenTelemetry::Trace::SpanContext.new(
        trace_id: ["0af7651916cd43dd8448eb211c80319c"].pack("H*"),
        span_id: ["b7ad6b7169203331"].pack("H*")
      )
    end

    it "gives the trace flags without the sampled bit" do
      expect(fields["trace_flags"]).to eq("00")
    end
  end
end
