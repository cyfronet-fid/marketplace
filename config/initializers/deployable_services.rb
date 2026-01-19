# frozen_string_literal: true

# Load deployable services configuration
# This includes Infrastructure Manager settings, EGI authentication, and cloud providers
Rails.application.configure do
  config.deployable_services = config_for(:deployable_services)
end
