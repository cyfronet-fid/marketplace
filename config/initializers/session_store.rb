# frozen_string_literal: true

if ENV["REDIS_URL"]
  url = ENV["REDIS_URL"]
else
  url = "redis://localhost:6379/0/mp-session"
end

if Rails.env.test?
  Rails.application.config.session_store :cookie_store,
    key: "_mp_session"
else
  Mp::Application.config.session_store :redis_store,
    servers: url,
    expire_after: 90.minutes,
    key: "_mp_session",
    threadsafe: false
end
