# frozen_string_literal: true

sidekiq_connection = {
  url: Mp::Application.config.redis_url
}

Sidekiq::Cron.configure do |config|
  config.cron_schedule_file = "config/schedule.yml"
end

Sidekiq.configure_server do |config|
  config.redis = sidekiq_connection
  config.average_scheduled_poll_interval = 1
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_connection
end

Sidekiq.strict_args!
