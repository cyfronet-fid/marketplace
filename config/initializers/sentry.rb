# frozen_string_literal: true

if Rails.env.production? && ENV["SENTRY_DSN"]
  require "sentry-ruby"

  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.environment = ENV["SENTRY_ENVIRONMENT"] || "production"
    config.traces_sample_rate = 0.5
    config.send_default_pii = true
  end
end
