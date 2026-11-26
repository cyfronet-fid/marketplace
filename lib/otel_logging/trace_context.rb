# frozen_string_literal: true

require "opentelemetry"

module OtelLogging
  # Trace fields of the active OpenTelemetry span. The names follow the
  # OpenTelemetry specification "Trace Context in non-OTLP Log Formats".
  # Without a tracing SDK no span is valid, and the context gives no fields.
  class TraceContext
    def to_h
      context = OpenTelemetry::Trace.current_span.context
      return {} unless context.valid?

      {
        "trace_id" => context.hex_trace_id,
        "span_id" => context.hex_span_id,
        "trace_flags" => context.trace_flags.sampled? ? "01" : "00"
      }
    end
  end
end
