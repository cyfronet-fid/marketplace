# frozen_string_literal: true

# Error tracking (Sentry), in every environment that sets SENTRY_DSN. The test
# environment and a local deploy leave SENTRY_DSN unset.
if ENV["SENTRY_DSN"].present?
  require "sentry-ruby"

  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.environment = ENV["SENTRY_ENVIRONMENT"] || Rails.env
    # MP_VERSION is "<compose project> <commit>" in the docker deployments;
    # the commit is the release of the events.
    config.release = ENV.fetch("MP_VERSION", "").split.last
    # The share of the requests stored as transactions.
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.01").to_f
    config.send_default_pii = true
    # Errors reported with Rails.error.report go to Sentry too. Exceptions
    # Sentry has already captured are not sent again.
    config.rails.register_error_subscriber = true
  end

  # All variants and all instances report to one Sentry project. The two tags
  # tell the events apart. config/initializers/variants.rb is not loaded yet
  # here, thus the variant comes from config/variants.yml directly. The
  # instance is the host of ROOT_URL.
  Sentry.set_tags(
    {
      variant: Rails.application.config_for(:variants)[:current],
      instance: URI.parse(ENV.fetch("ROOT_URL", "")).host
    }.compact
  )
end
