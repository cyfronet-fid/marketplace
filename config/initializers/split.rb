# frozen_string_literal: true

require "split/dashboard"

cookie_adapter = Split::Persistence::CookieAdapter
redis_adapter = Split::Persistence::RedisAdapter.with_config(
    lookup_by: -> (context) { context.request.env["warden"]&.user&.id },
    expire_seconds: 2592000)

Split.configure do |config|
  config.persistence = Split::Persistence::DualAdapter.with_config(
      logged_in: -> (context) { context.request.env["warden"]&.user&.id.present? },
      logged_in_adapter: redis_adapter,
      logged_out_adapter: cookie_adapter)
  config.persistence_cookie_length = 2592000 # 30 days
  config.experiments = YAML.load_file "config/experiments.yml"
  config.allow_multiple_experiments = true
  config.include_rails_helper = true
end
