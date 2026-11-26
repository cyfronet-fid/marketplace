# frozen_string_literal: true

module OtelLogging
  # The log entry of one HTTP request, for lograge. The object is the lograge
  # formatter and the source of the custom lograge fields. The names follow
  # the OpenTelemetry HTTP conventions. The entry has no request parameters.
  class RequestEntry
    RENAMED = {
      method: "http.request.method",
      path: "url.path",
      status: "http.response.status_code",
      duration: "duration_ms"
    }.freeze
    CUSTOM = %w[user.id exception.type exception.message].freeze

    # The lograge formatter. JsonFormatter writes the Hash as fields.
    def call(data)
      RENAMED
        .to_h { |lograge_key, field| [field, data[lograge_key]] }
        .merge(data.slice(*CUSTOM))
        .merge("body" => "#{data[:method]} #{data[:path]} #{data[:status]}")
        .compact
    end

    # lograge custom_options: fields from the process_action event.
    def event_fields(event)
      type, message = event.payload[:exception]
      { "exception.type" => type, "exception.message" => message }
    end

    # lograge custom_payload: fields from the controller. The internal id is
    # the only reference to the user.
    def controller_fields(controller)
      { "user.id" => controller.try(:current_user)&.id }
    end
  end
end
