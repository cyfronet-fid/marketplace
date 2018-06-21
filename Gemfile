# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.5.1"

gem "rails", "~> 5.2.0"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 3.11"

gem "sass-rails", "~> 5.0"
gem "uglifier", ">= 1.3.0"
gem "webpacker"
gem "haml-rails"
gem "turbolinks", "~> 5", require: false

gem "bootsnap", ">= 1.1.0", require: false

gem "ancestry"
gem "gretel"
gem "will_paginate", "~> 3.1.0"

gem "elasticsearch-model"
gem "elasticsearch-rails"

gem "devise"
gem "omniauth"
gem "omniauth_openid_connect"
gem "pundit"

# Markdown
gem "github-markup"
gem "redcarpet"

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]

  gem "rspec-rails", "~> 3.7"

  gem "pry"
  gem "pry-byebug"
  gem "pry-rails"
  gem "pry-doc"
  gem "pry-nav"
end

group :development do
  gem "web-console", ">= 3.3.0"
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"

  gem "faker", require: false

  gem "rubocop-rails"
  gem "overcommit", require: false
end

group :test do
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "capybara"
  gem "database_cleaner"
end

gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :production do
  gem "sentry-raven"
end
