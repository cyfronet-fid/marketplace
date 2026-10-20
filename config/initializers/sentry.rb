# frozen_string_literal: true

# Error tracking and logs (Sentry or GlitchTip), in every environment that
# sets SENTRY_DSN; the test environment leaves it unset.
if ENV["SENTRY_DSN"]
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

    # Logs for the Logs view: one entry per request, job and mail
    # (SENTRY_LOGS=false turns them off). SQL queries only with
    # SENTRY_LOGS_QUERIES=true, they are many. Sentry.logger.info("...") adds
    # an entry of the application.
    config.enable_logs = ActiveModel::Type::Boolean.new.cast(ENV.fetch("SENTRY_LOGS", true))
    config.rails.structured_logging.subscribers = {
      action_controller: Sentry::Rails::LogSubscribers::ActionControllerSubscriber,
      active_job: Sentry::Rails::LogSubscribers::ActiveJobSubscriber,
      action_mailer: Sentry::Rails::LogSubscribers::ActionMailerSubscriber
    }
    if ActiveModel::Type::Boolean.new.cast(ENV.fetch("SENTRY_LOGS_QUERIES", false))
      config.rails.structured_logging.subscribers[:active_record] =
        Sentry::Rails::LogSubscribers::ActiveRecordSubscriber
    end
  end
end
