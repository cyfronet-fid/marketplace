# frozen_string_literal: true

require "sidekiq"

module OtelLogging
  # Fields of the Sidekiq job that the current thread runs. The names follow
  # the OpenTelemetry messaging conventions and the Sidekiq instrumentation of
  # OpenTelemetry. Sidekiq keeps the context of one job only.
  class JobContext
    SYSTEM = "sidekiq"

    def to_h
      job = Sidekiq::Context.current
      return {} unless job[:jid]

      {
        "messaging.system" => SYSTEM,
        "messaging.message.id" => job[:jid],
        "messaging.destination.name" => job[:queue],
        "messaging.sidekiq.job_class" => job[:class],
        "duration_ms" => milliseconds(job[:elapsed])
      }.compact
    end

    private

    # Sidekiq records the elapsed time in seconds.
    def milliseconds(seconds)
      seconds && (seconds * 1000).round
    end
  end
end
