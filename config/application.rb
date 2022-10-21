# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mp
  class Application < Rails::Application
    # IMPORTANT!!! Prevent crashing workers on thread error !!!
    # The most common errored place is Image Magic conversion to PNG
    # This flag will influence all threads in the application
    Thread.abort_on_exception = true

    # config.assets.enabled = false

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.autoload_paths << Rails.root.join("lib")

    default_redis_url = Rails.env == "test" ? "redis://localhost:6379/1" : "redis://localhost:6379/0"

    config.redis_url = ENV["REDIS_URL"] || default_redis_url

    config.active_storage.queues.analysis = :active_storage_analysis
    config.active_storage.queues.purge = :active_storage_purge

    config.matomo_url = ENV.fetch("MP_MATOMO_URL", "//providers.eosc-portal.eu/matomo/")
    config.matomo_site_id = ENV.fetch("MP_MATOMO_SITE_ID", 1)

    # Hierachical locales file structure
    # see https://guides.rubyonrails.org/i18n.html#configure-the-i18n-module
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]

    # Views and locales customization
    # The dir structure pointed by `$CUSTOMIZATION_PATH` should looks as follow:
    #   - views          // custom views
    #   - javascript     // custom scss files (see `config/webpack/environment.js`)
    #   - config/locales // custom locales
    if ENV["CUSTOMIZATION_PATH"].present?
      config.paths["app/views"].unshift(File.join(ENV["CUSTOMIZATION_PATH"], "views"))
      config.i18n.load_path +=
        Dir[Pathname.new(ENV["CUSTOMIZATION_PATH"]).join("config", "locales", "**", "*.{rb,yml}")]
    end

    config.portal_base_url = ENV["PORTAL_BASE_URL"].present? ? ENV["PORTAL_BASE_URL"] : "https://eosc-portal.eu"

    config.providers_dashboard_url = ENV.fetch("PROVIDERS_DASHBOARD_URL", "https://beta.providers.eosc-portal.eu")

    config.monitoring_data_host = ENV.fetch("MONITORING_DATA_URL", "https://api.devel.argo.grnet.gr/api")
    config.monitoring_data_token = ENV.fetch("MONITORING_DATA_TOKEN",
                                             Rails.application.credentials.monitoring_data[:access_token])

    config.similar_services_host = ENV.fetch("SIMILAR_SERVICES_HOST", "http://docker-fid.grid.cyf-kr.edu.pl:4559")
    config.recommender_host = ENV.fetch("RECOMMENDER_HOST", nil)
    config.recommendation_engine = ENV.fetch("RECOMMENDATION_ENGINE", "RL")
    config.auth_mock = ENV.fetch("AUTH_MOCK", nil)
    config.eosc_commons_base_url = ENV.fetch("EOSC_COMMONS_BASE_URL", "https://s3.cloud.cyfronet.pl/eosc-portal-common/")

    config.eosc_commons_env = ENV.fetch("EOSC_COMMONS_ENV", "production")

    config.user_actions_target = ENV.fetch("USER_ACTIONS_TARGET", "all")

    config.profile_4_enabled = ENV.fetch("PROFILE_4_ENABLED", true)
    config.home_page_external_links_enabled = ENV.fetch("HOME_PAGE_EXTERNAL_LINKS_ENABLED", true)
    config.search_service_base_url = ENV.fetch("SEARCH_SERVICE_BASE_URL", "https://search.eosc-portal.eu")

    config.mp_stomp_publisher_enabled = ENV.fetch("MP_STOMP_PUBLISHER_ENABLED") { Rails.env.test? }
  end
end
