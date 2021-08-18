# frozen_string_literal: true

Recaptcha.configure do |config|
  config.site_key = ENV["RECAPTCHA_SITE_KEY"] ||
      Rails.application.credentials.recaptcha.dig(Rails.env.to_sym, :site_key)
  config.secret_key = ENV["RECAPTCHA_SECRET_KEY"] ||
      Rails.application.credentials.recaptcha.dig(Rails.env.to_sym, :secret_key)

  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://myproxy.com.au:8080'
end
