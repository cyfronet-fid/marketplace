# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# enabling bootsnap breaks debugging, the problem apparently exists only for rails 5.2
# after upgrading rails it can be removed
if (ENV["RAILS_ENV"] || "development") != "development"
  require "bootsnap/setup" # Speed up boot time by caching expensive operations.
end
