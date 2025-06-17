# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.6"

gem "rails", "~> 7.2.1"
gem "pg", "~> 1.5", "< 2.0"
gem "puma"
gem "nori"

gem "uglifier", "~> 4.2"
gem "sprockets-rails"
gem "jsbundling-rails"
gem "cssbundling-rails"
gem "view_component", "~> 2.83"
gem "haml-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "render_async"

gem "bootsnap", "~> 1.18", require: false
gem "colorize", "~> 1.1", require: false

gem "ancestry"
gem "gretel"
gem "pagy"
gem "simple_form"
gem "friendly_id", "~> 5.5"
gem "acts-as-taggable-on"
gem "countries"
gem "i18n_data"
gem "humanize"

gem "activestorage-validator"
gem "image_processing", ">= 1.2"
gem "marcel"

# translations
gem "fast_gettext"
gem "gettext_i18n_rails"
gem "gettext", "~> 3.4", require: false, group: :development
gem "ruby_parser", require: false, group: :development

# turbo-charged counter caches
gem "counter_culture", "~> 3.7"

# validation
gem "valid_email2"
gem "json-schema"
gem "public_suffix"

gem "searchkick"
gem "elasticsearch", "7.6.0"

gem "devise"
gem "omniauth"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"
gem "rack-cors"
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
gem "savon", "~> 2.15"

gem "google-apis-analyticsreporting_v4", "~> 0.5"

gem "sidekiq"
gem "sidekiq-limit_fetch", "~>4.4"

gem "stomp"

gem "aws-sdk-s3", require: false

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]

  gem "rspec-rails", "~> 6.1"
  gem "rspec-retry"
  gem "rswag-specs"
  gem "pry"
  gem "pry-byebug", "~>3.10"
  gem "pry-rails"
  gem "pry-nav"

  gem "dotenv-rails"
  gem "webmock"
  gem "foreman"
end

group :development do
  gem "web-console", "~> 4.2"
  gem "listen"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.1"
  gem "spring-commands-rspec"
  gem "prettier", require: false
  gem "overcommit", require: false
  gem "haml_lint", require: false
  gem "scss_lint", require: false
  gem "mdl"
end

group :test do
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "capybara"
  gem "database_cleaner"
  gem "rack_session_access"
  gem "selenium-webdriver"
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
gem "timeout", "~>0.4"

# Use Redis for Action Cable
gem "redis", "~> 5.2"
gem "redis-actionpack", "~> 5.4"
