# frozen_string_literal: true

module Matomo
  # Every Matomo setting of this Node, read from the MP_MATOMO_* env vars
  # (ADR-0008 D2, D3). config/application.rb builds it once at boot as
  # config.matomo; no other code reads MP_MATOMO_*. Shared mode will only
  # change how the object is built (per tenant), not its callers.
  #
  # config/application.rb requires this file before autoloading exists, so
  # lib/matomo is outside Zeitwerk; the rest of the Matomo namespace
  # (app/services/matomo) is autoloaded as usual.
  class Configuration
    # Raised at boot when Matomo is enabled with incomplete settings.
    class Error < StandardError
    end

    DEFAULT_SYNC_CRON = "15 2 * * *"

    attr_reader :url, :site_id, :token_auth, :sync_cron

    def initialize(env)
      @enabled = ActiveModel::Type::Boolean.new.cast(env.fetch("MP_MATOMO_ENABLED", false))
      @url = with_trailing_slash(env["MP_MATOMO_URL"])
      # No default: on a central Matomo it would send this Node's traffic into another Node's site.
      @site_id = env["MP_MATOMO_SITE_ID"].presence&.strip
      # View-only token of the Node's reporting user, for the view sync only. Tracking works without it.
      @token_auth = env["MP_MATOMO_TOKEN_AUTH"].presence
      @sync_cron = env["MP_MATOMO_SYNC_CRON"].presence || DEFAULT_SYNC_CRON

      validate! if enabled?
    end

    def enabled?
      @enabled
    end

    # The token never leaves the server: not in a console, a log or an error report.
    def inspect
      "#<#{self.class.name} enabled=#{enabled?} url=#{url.inspect} site_id=#{site_id.inspect} " \
        "token_auth=#{token_auth ? "[FILTERED]" : "nil"} sync_cron=#{sync_cron.inspect}>"
    end

    private

    # The tracker appends matomo.js and matomo.php, the reporting client index.php.
    def with_trailing_slash(value)
      value = value&.strip
      "#{value.delete_suffix("/")}/" if value.present?
    end

    def validate!
      raise Error, "MP_MATOMO_URL is required when MP_MATOMO_ENABLED is true" if url.blank?
      unless absolute_http_url?(url)
        # Protocol-relative URLs (//host/), which the old integration required, are rejected too.
        raise Error, "MP_MATOMO_URL must be an absolute http(s) URL, such as https://matomo.example.org/ " \
                     "(got #{url.inspect})"
      end
      raise Error, "MP_MATOMO_SITE_ID is required when MP_MATOMO_ENABLED is true" if site_id.blank?
    end

    def absolute_http_url?(value)
      uri = URI.parse(value)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end
  end
end
