# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.11"

gem "rails", "~> 7.2.3"
gem "pg", "~> 1.5", "< 2.0"
gem "puma", "~> 7.0"
gem "nori"

# transitive deps pinned to their current major, kept off auto-bump
gem "minitest", "~> 5.27"
gem "jwt", "~> 2.10"
gem "parallel", "~> 1.27"

gem "uglifier", "~> 4.2"
gem "sprockets-rails"
gem "jsbundling-rails"
gem "cssbundling-rails"
gem "view_component", "~> 2.83"
gem "haml", "~> 6.3"
gem "haml-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "render_async"

gem "bootsnap", "~> 1.18", require: false
gem "colorize", "~> 1.1", require: false

gem "ancestry", "~> 4.3"
gem "gretel"
gem "pagy", "~> 9.4"
gem "simple_form"
gem "friendly_id", "~> 5.5"
gem "acts-as-taggable-on", "~> 12.0"
gem "countries"
gem "i18n_data"
gem "humanize"

gem "activestorage-validator"
gem "image_processing", "~> 1.14"
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
gem "json-schema", "~> 5.2"
gem "public_suffix", "~> 6.0"

gem "searchkick", "~> 5.5"
gem "elasticsearch", "7.6.0"

gem "devise", "~> 4.9"
gem "omniauth"
gem "omniauth_openid_connect", "~> 0.6"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "rack-cors"
gem "pundit", "~> 2.0"
gem "role_model"
gem "recaptcha", require: "recaptcha/rails"
# Markdown
gem "github-markup", "~> 5.0"
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

gem "sidekiq", ">= 8.0.9"
gem "sidekiq-limit_fetch", "~>4.4"

gem "stomp"

gem "aws-sdk-s3", require: false

group :development, :test do
  gem "byebug", platforms: [:mri, :windows]

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
  gem "brakeman", "~> 7.1"
end

group :development do
  gem "web-console", "~> 4.2"
  gem "listen"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.1"
  gem "spring-commands-rspec"
  gem "prettier", require: false
  gem "haml_lint", require: false
  gem "scss_lint", require: false
  gem "mdl"
  gem "debride", require: false
end

group :test do
  gem "parallel_tests"
  gem "factory_bot_rails"
  gem "shoulda-matchers", "~> 6.5"
  gem "capybara"
  gem "database_cleaner"
  gem "rack_session_access"
  gem "selenium-webdriver"
  gem "rails-controller-testing"
end

gem "tzinfo-data", platforms: [:windows, :jruby]

group :production do
  gem "sentry-ruby", "~> 5.28"
  gem "sentry-rails", "~> 5.28"
  gem "sentry-sidekiq", "~> 5.28"
end

gem "faraday", "~> 1.10"
gem "faraday_middleware"
gem "reverse_markdown"
gem "auto_strip_attributes"

# Fix for puma memory leak
gem "puma_worker_killer"
gem "timeout", "~>0.4"

# Use Redis for Action Cable
gem "redis", "~> 5.2"
gem "redis-actionpack", "~> 5.4"
