# frozen_string_literal: true

if Rails.env.production? && ENV["SENTRY_DSN"]
  require "raven"

  Raven.configure do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.environments = [ENV["SENTRY_ENVIRONMENT"] || "production"]
    config.sanitize_fields =
      Rails.application.config.filter_parameters.map(&:to_s)
  end
end
