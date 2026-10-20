# frozen_string_literal: true

# Load deployable services configuration
# This includes Application Deployment Manager (ADM) settings, EGI authentication, and cloud providers
Rails.application.configure do
  config.deployable_services = config_for(:deployable_services)
end
