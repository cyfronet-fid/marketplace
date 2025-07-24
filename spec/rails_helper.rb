# frozen_string_literal: true

require "webmock/rspec"
require "spec_helper"
require "view_component/test_helpers"

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!

# Remove after this is fixed
# https://github.com/rspec/rspec-rails/issues/1897
require "action_dispatch/system_testing/server"
ActionDispatch::SystemTesting::Server.silence_puma = true
require "action_dispatch/system_test_case"

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  config.include ExternalServiceDataHelper

  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Add view component helpers
  config.include ViewComponent::TestHelpers, type: :component

  Capybara.register_driver :chrome do |app|
    caps = Selenium::WebDriver::Chrome::Options.new(args: %w[no-sandbox headless disable-gpu window-size=1000,1000])
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: caps)
  end

  Capybara.javascript_driver = :chrome

  Capybara.default_max_wait_time = 20

  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers
  config.include TurboAssertionsHelper

  # Use mock of middleware
  config.include Devise::Test::ControllerHelpers, type: :controller
end

OmniAuth.config.test_mode = true

WebMock.allow_net_connect!
