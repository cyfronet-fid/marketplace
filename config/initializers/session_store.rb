# frozen_string_literal: true

if Rails.env.test?
  Rails.application.config.session_store :cookie_store,
    key: "_mp_session"
else
  Mp::Application.config.session_store :redis_store,
    servers: "#{Mp::Application.config.redis_url}/mp-session",
    expire_after: 90.minutes,
    key: "_mp_session",
    threadsafe: false
end
