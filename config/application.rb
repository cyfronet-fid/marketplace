# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mp
  class Application < Rails::Application
    config.assets.enabled = false
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.autoload_paths << Rails.root.join("lib")

    default_redis_url = if Rails.env == "test" then "redis://localhost:6379/1" else "redis://localhost:6379/0" end

    config.redis_url = ENV["REDIS_URL"] || default_redis_url

    config.active_storage.queues.analysis = :active_storage_analysis
    config.active_storage.queues.purge = :active_storage_purge

    config.matomo_url = ENV["MP_MATOMO_URL"] || "//providers.eosc-portal.eu/matomo/"
    config.matomo_site_id = ENV["MP_MATOMO_SITE_ID"] || 1

    # Hierachical locales file structure
    # see https://guides.rubyonrails.org/i18n.html#configure-the-i18n-module
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    # Views and locales customization
    # The dir structure pointed by `$CUSTOMIZATION_PATH` should looks as follow:
    #   - views          // custom views
    #   - javascript     // custom scss files (see `config/webpack/environment.js`)
    #   - config/locales // custom locales
    if ENV["CUSTOMIZATION_PATH"].present?
      config.paths['app/views'].unshift(File.join(ENV["CUSTOMIZATION_PATH"], "views"))
      config.i18n.load_path +=
        Dir[Pathname.new(ENV["CUSTOMIZATION_PATH"]).join('config', 'locales', '**', '*.{rb,yml}')]
    end


    config.portal_base_url = ENV["PORTAL_BASE_URL"].present? ?
                                 ENV["PORTAL_BASE_URL"] : "https://eosc-portal.eu"

    config.providers_dashboard_url = ENV["PROVIDERS_DASHBOARD_URL"].present? ?
      ENV["PROVIDERS_DASHBOARD_URL"] : " https://beta.providers.eosc-portal.eu"

    config.recommender_host = ENV["RECOMMENDER_HOST"]
    config.auth_mock = ENV["AUTH_MOCK"]

    config.export_provider_component_host = ENV["EXPORT_PROVIDER_COMPONENT_HOST"]
    config.pc_export_token = ENV["PC_EXPORT_TOKEN"]
  end
end
