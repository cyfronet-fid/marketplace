# frozen_string_literal: true

require "json"
require "time"

module OtelLogging
  # Formatter of a Ruby logger. One log entry is one JSON object on one line.
  # The keys follow the OpenTelemetry log data model. Each context supplies
  # more fields with #to_h. A Hash message supplies its keys as fields.
  class JsonFormatter
    SEVERITY_NUMBERS = { "DEBUG" => 5, "INFO" => 9, "WARN" => 13, "ERROR" => 17, "FATAL" => 21 }.freeze

    def initialize(contexts: [])
      @contexts = contexts
    end

    # The interface of Logger::Formatter.
    def call(severity, time, _progname, message)
      "#{entry(severity, time, message)}\n"
    end

    # The entry without the line end. A message that JSON cannot write gives
    # its inspected text as the body: the formatter must not raise.
    def entry(severity, time, message)
      JSON.generate(fields(severity, time, message))
    rescue JSON::GeneratorError, JSON::NestingError
      JSON.generate(fields(severity, time, message.inspect))
    end

    private

    def fields(severity, time, message)
      @contexts
        .reduce(severity_fields(severity, time)) { |fields, context| fields.merge(context.to_h) }
        .merge(message_fields(message))
        .compact
    end

    def severity_fields(severity, time)
      {
        "timestamp" => time.utc.iso8601(6),
        "severity_text" => severity,
        "severity_number" => SEVERITY_NUMBERS[severity]
      }
    end

    def message_fields(message)
      case message
      when Hash
        message.transform_keys(&:to_s)
      when Exception
        exception_fields(message)
      else
        { "body" => text(message) }
      end
    end

    def exception_fields(exception)
      {
        "body" => text(exception.message),
        "exception.type" => exception.class.name,
        "exception.message" => text(exception.message),
        "exception.stacktrace" => exception.backtrace&.join("\n")
      }
    end

    # JSON accepts valid UTF-8 only.
    def text(message)
      string = message.is_a?(String) ? message : message.inspect
      return string.scrub if string.encoding == Encoding::UTF_8

      string.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    end
  end
end
