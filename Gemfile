# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.3"

gem "rails", "~> 6.1.5"
gem "pg", ">= 0.18", "< 2.0"
gem "puma"
gem "nori"

gem "uglifier", ">= 1.3.0"
gem "webpacker", "~> 5.0"
gem "view_component", require: "view_component/engine"
gem "haml-rails"
gem "turbolinks", "~> 5", require: false

gem "bootsnap", ">= 1.4.2", require: false
gem "colorize", ">= 0.8.1", require: false

gem "ancestry"
gem "gretel"
gem "pagy"
gem "simple_form"
gem "friendly_id", "~> 5.2.0"
gem "acts-as-taggable-on"
gem "countries"

gem "activestorage-validator"
gem "image_processing"

# translations
gem "fast_gettext"
gem "gettext_i18n_rails"
gem "i18n_data"
gem "gettext", ">=3.0.2", require: false, group: :development
gem "ruby_parser", require: false, group: :development

# turbo-charged counter caches
gem "counter_culture", "~> 2.0"

# validation
gem "valid_email2"
gem "json-schema"
gem "public_suffix"

gem "searchkick"
gem "elasticsearch", "7.6.0"

gem "devise"
gem "omniauth"
gem "omniauth_openid_connect", github: "Boardeaser/omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"
gem "pundit", "~> 2.0"
gem "role_model"
gem "recaptcha", require: "recaptcha/rails"
# Markdown
gem "github-markup"
gem "redcarpet"

# api
gem "rswag-api"
gem "rswag-ui"
gem "simple_token_authentication"
gem "active_model_serializers"

# jira
gem "jira-ruby"

# soap
gem "savon", "~> 2.12.0"

gem "google-apis-analyticsreporting_v4", "~> 0.5"

gem "redis-rails"
gem "sidekiq"
gem "sidekiq-limit_fetch", "~>4.2.0"

gem "stomp"

gem "aws-sdk-s3", require: false

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]

  gem "rspec-rails", "~> 3.8.2"
  gem "rswag-specs"
  gem "pry"
  gem "pry-byebug"
  gem "pry-rails"
  gem "pry-nav"

  gem "dotenv-rails"
  gem "webmock"
end

group :development do
  gem "web-console", ">= 3.3.0"
  gem "listen"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "spring-commands-rspec"
  gem "prettier", require: false
  gem "overcommit", require: false
  gem "haml_lint", require: false
  gem "scss_lint", require: false
end

group :test do
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "capybara"
  gem "database_cleaner"
  gem "rack_session_access"
  gem "selenium-webdriver"
  gem "webdrivers"
end

gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :production do
  gem "sentry-ruby"
  gem "sentry-rails"
  gem "sentry-sidekiq"
end

gem "faraday"
gem "faraday_middleware"
gem "reverse_markdown"
gem "auto_strip_attributes"

# Fix for puma memory leak
gem "puma_worker_killer"
gem "timeout"
