# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "humanize"

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
    config.load_defaults 7.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.action_dispatch.return_only_request_media_type_on_content_type = false
    config.active_storage.multiple_file_field_include_hidden = true
    config.active_storage.variant_processor = :mini_magick
    config.active_support.cache_format_version = 7.1
    config.active_support.disable_to_s_conversion = true

    config.autoload_lib(ignore: %w[assets tasks])

    default_redis_url = Rails.env == "test" ? "redis://localhost:6379/1" : "redis://localhost:6379/0"

    config.redis_url = ENV.fetch("REDIS_URL", default_redis_url)

    config.active_storage.queues.analysis = :active_storage_analysis
    config.active_storage.queues.purge = :active_storage_purge

    config.matomo_url = ENV.fetch("MP_MATOMO_URL", "//providers.eosc-portal.eu/matomo/")
    config.matomo_site_id = ENV.fetch("MP_MATOMO_SITE_ID", 1).to_i

    # Hierachical locales file structure
    # see https://guides.rubyonrails.org/i18n.html#configure-the-i18n-module
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]

    # Views and locales customization
    # The dir structure pointed by `$CUSTOMIZATION_PATH` should looks as follow:
    #   - views          // custom views
    #   - javascript     // custom scss files (see `config/webpack/environment.js`)
    #   - config/locales // custom locales

    config.is_recommendation_panel = ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOW_RECOMMENDATION_PANEL", true))
    if ENV["CUSTOMIZATION_PATH"].present?
      config.paths["app/views"].unshift(File.join(ENV["CUSTOMIZATION_PATH"], "views"))
      config.i18n.load_path +=
        Dir[Pathname.new(ENV["CUSTOMIZATION_PATH"]).join("config", "locales", "**", "*.{rb,yml}")]
    end

    config.portal_base_url = ENV.fetch("PORTAL_BASE_URL", "https://eosc-portal.eu")

    config.providers_dashboard_url = ENV.fetch("PROVIDERS_DASHBOARD_URL", "https://beta.providers.eosc-portal.eu")
    config.google_api_key_path = ENV.fetch("GOOGLE_AUTH_KEY_FILEPATH", "config/google_api_key.json")
    config.monitoring_data_enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("MONITORING_DATA_ENABLED", false))
    config.monitoring_data_host = ENV.fetch("MONITORING_DATA_URL", "https://api.devel.argo.grnet.gr/api")
    config.monitoring_data_token = ENV.fetch("MONITORING_DATA_TOKEN", nil)
    config.monitoring_data_ui_url = ENV.fetch("MONITORING_DATA_UI_URL", nil)
    config.monitoring_data_path = ENV.fetch("MONITORING_DATA_UI_PATH", nil)
    config.similar_services_host = ENV.fetch("SIMILAR_SERVICES_HOST", nil)
    config.recommender_host = ENV.fetch("RECOMMENDER_HOST", nil)
    config.recommendation_engine = ENV.fetch("RECOMMENDATION_ENGINE", "RL")
    config.auth_mock = ENV.fetch("AUTH_MOCK", false)
    config.eosc_commons_base_url = ENV.fetch("EOSC_COMMONS_BASE_URL",
                                             "https://s3.cloud.cyfronet.pl/eosc-portal-common/")
    config.eosc_commons_env = ENV.fetch("EOSC_COMMONS_ENV", "production")
    config.user_actions_target = ENV.fetch("USER_ACTIONS_TARGET", "all")

    config.profile_4_enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("PROFILE_4_ENABLED", false))
    config.home_page_external_links_enabled = ActiveModel::Type::Boolean.new.cast(
      ENV.fetch("HOME_PAGE_EXTERNAL_LINKS_ENABLED", false))
    config.search_service_base_url = ENV.fetch("SEARCH_SERVICE_BASE_URL", "https://search.marketplace.eosc-portal.eu")
    config.search_service_research_product_endpoint = ENV.fetch("SEARCH_SERVICE_RESEARCH_PRODUCT_ENDPOINT",
                                                                "/api/web/research-product/")
    config.user_dashboard_url = ENV.fetch("USER_DASHBOARD_URL",
                                          "https://eosc-user-dashboard.docker-fid.grid.cyf-kr.edu.pl")

    config.resource_cache_ttl = ENV.fetch("ESS_RESOURCE_CACHE_TTL", "60").to_i.seconds

    config.mp_stomp_publisher_enabled = ActiveModel::Type::Boolean.new.cast(
      ENV.fetch("MP_STOMP_PUBLISHER_ENABLED", Rails.env.test?))

    config.enable_external_search = ActiveModel::Type::Boolean.new.cast(ENV.fetch("MP_ENABLE_EXTERNAL_SEARCH", false))
    config.analytics_enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ANALYTICS_ENABLED", false))
    config.whitelabel = ENV.fetch("MP_WHITELABEL", true)
  end
end
