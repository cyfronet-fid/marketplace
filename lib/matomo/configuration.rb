# frozen_string_literal: true

require "ipaddr"

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
    # Matomo numbers its sites from 1.
    SITE_ID_FORMAT = /\A[1-9]\d*\z/

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
      "#{value.sub(%r{/+\z}, "")}/" if value.present?
    end

    def validate!
      validate_url!
      raise Error, "MP_MATOMO_SITE_ID is required when MP_MATOMO_ENABLED is true" if site_id.blank?
      return if SITE_ID_FORMAT.match?(site_id)

      raise Error, "MP_MATOMO_SITE_ID must be a positive whole number, such as 12 (got #{site_id.inspect})"
    end

    def validate_url!
      raise Error, "MP_MATOMO_URL is required when MP_MATOMO_ENABLED is true" if url.blank?

      uri = parse_url
      unless base_url?(uri)
        raise Error, "MP_MATOMO_URL must be an absolute http(s) URL without a query or fragment, " \
                     "such as https://matomo.example.org/ (got #{url.inspect})"
      end
      return if token_auth.nil? || uri.scheme == "https" || loopback?(uri.hostname)

      # The reporting client sends the token in its request body.
      raise Error, "MP_MATOMO_URL must use https while MP_MATOMO_TOKEN_AUTH is set, " \
                   "unless Matomo runs on this host (got #{url.inspect})"
    end

    def parse_url
      URI.parse(url)
    rescue URI::InvalidURIError
      nil
    end

    # Protocol-relative URLs (//host/), which the old integration required, are
    # rejected too. A query or fragment would come before the file names
    # appended to the URL.
    def base_url?(uri)
      uri.is_a?(URI::HTTP) && uri.host.present? && uri.query.nil? && uri.fragment.nil?
    end

    def loopback?(host)
      host == "localhost" || IPAddr.new(host).loopback?
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
