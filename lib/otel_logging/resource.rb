# frozen_string_literal: true

require "uri"

module OtelLogging
  # Fields that stay the same during the life of the process. The names are
  # OpenTelemetry resource attributes. The values come from the same variables
  # as the Sentry tags (config/initializers/sentry.rb).
  class Resource
    NAMESPACE = "marketplace"

    def self.from_env(env, service_name:)
      new(
        service_name: service_name,
        version: env.fetch("MP_VERSION", "").split.last,
        environment: env["SENTRY_ENVIRONMENT"] || env["RAILS_ENV"],
        variant: env["MARKETPLACE_VARIANT"],
        instance: URI.parse(env.fetch("ROOT_URL", "")).host
      )
    end

    def initialize(service_name:, version: nil, environment: nil, variant: nil, instance: nil)
      @fields = {
        "service.namespace" => NAMESPACE,
        "service.name" => service_name,
        "service.version" => version,
        "deployment.environment.name" => environment,
        "mp.variant" => variant,
        "mp.instance" => instance
      }.compact.freeze
    end

    def to_h
      @fields
    end
  end
end
