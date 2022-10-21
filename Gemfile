# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.2"

gem "rails", "~> 7.0.4"
gem "pg", ">= 0.18", "< 2.0"
gem "puma"
gem "nori"

gem "uglifier", ">= 1.3.0"
gem "webpacker", "~> 5.0"
gem "view_component"
gem "haml-rails"
gem "turbolinks", "~> 5", require: false
gem "render_async"

gem "bootsnap", ">= 1.15.0", require: false
gem "colorize", ">= 0.8.1", require: false

gem "ancestry"
gem "gretel"
gem "pagy"
gem "simple_form"
gem "friendly_id", "~> 5.5.0"
gem "acts-as-taggable-on"
gem "countries"

gem "activestorage-validator"
gem "image_processing"

# translations
gem "i18n_data", "> 0.16.0"
gem "fast_gettext"
gem "gettext_i18n_rails"
gem "gettext", ">=3.0.2", require: false, group: :development
gem "ruby_parser", require: false, group: :development

# turbo-charged counter caches
gem "counter_culture", "~> 3.3"

# validation
gem "valid_email2"
gem "json-schema"
gem "public_suffix"

gem "searchkick"
gem "elasticsearch", "8.5.2"

gem "devise"
gem "omniauth"
gem "omniauth_openid_connect"
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
gem "simple_token_authentication", "~> 1.18", ">= 1.18.1"
gem "active_model_serializers"

# jira
gem "jira-ruby"

# soap
gem "savon", "~> 2.12.0"

gem "google-apis-analyticsreporting_v4", "~> 0.5"

gem "redis-rails"
gem "sidekiq", "<7"

gem "stomp"

gem "aws-sdk-s3", require: false

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]

  gem "rspec-rails", "~> 3.8.2"
  gem "rswag-specs"
  gem "pry"
  gem "pry-byebug", "~>3.10.0"
  gem "pry-rails"
  gem "pry-nav"

  gem "dotenv-rails"
  gem "webmock"
end

group :development do
  gem "web-console", ">= 3.3.0"
  gem "listen"
  gem "spring", "~> 4.0.0"
  gem "spring-watcher-listen", "~> 2.1.0"
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
