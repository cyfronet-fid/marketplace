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

    config.assets.enabled = false

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

    config.matomo_url = ENV["MP_MATOMO_URL"] || "//providers.eosc-portal.eu/matomo/"
    config.matomo_site_id = ENV["MP_MATOMO_SITE_ID"] || 1

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

    config.providers_dashboard_url =
      if ENV["PROVIDERS_DASHBOARD_URL"].present?
        ENV["PROVIDERS_DASHBOARD_URL"]
      else
        "https://beta.providers.eosc-portal.eu"
      end

    config.monitoring_data_host = ENV.fetch("MONITORING_DATA_URL", "https://api.devel.argo.grnet.gr/api")
    config.monitoring_data_token = ENV.fetch("MONITORING_DATA_TOKEN",
                                             Rails.application.credentials.monitoring_data[:access_token])
    config.similar_services_host = ENV["SIMILAR_SERVICES_HOST"] || "http://docker-fid.grid.cyf-kr.edu.pl:4559"
    config.recommender_host = ENV["RECOMMENDER_HOST"]
    config.recommendation_engine = ENV["RECOMMENDATION_ENGINE"] || "RL"
    config.auth_mock = ENV["AUTH_MOCK"]
    config.eosc_commons_base_url =
      if ENV["EOSC_COMMONS_BASE_URL"].present?
        ENV["EOSC_COMMONS_BASE_URL"]
      else
        "https://s3.cloud.cyfronet.pl/eosc-portal-common/"
      end
    config.eosc_commons_env = ENV["EOSC_COMMONS_ENV"].present? ? ENV["EOSC_COMMONS_ENV"] : "production"

    config.user_actions_target = ENV["USER_ACTIONS_TARGET"].present? ? ENV["USER_ACTIONS_TARGET"] : "all"

    config.profile_4_enabled = ENV["PROFILE_4_ENABLED"].present? ? ENV["PROFILE_4_ENABLED"] : false
    config.home_page_external_links_enabled =
      ENV["HOME_PAGE_EXTERNAL_LINKS_ENABLED"].present? ? ENV["HOME_PAGE_EXTERNAL_LINKS_ENABLED"] : true
    config.search_service_base_url = ENV.fetch("SEARCH_SERVICE_BASE_URL", "https://search.marketplace.eosc-portal.eu")

    config.mp_stomp_publisher_enabled =
      if ENV["MP_STOMP_PUBLISHER_ENABLED"].present?
        ENV["MP_STOMP_PUBLISHER_ENABLED"]
      else
        Rails.env.test?
      end
  end
end
