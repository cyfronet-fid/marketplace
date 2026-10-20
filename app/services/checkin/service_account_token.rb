# frozen_string_literal: true

# EGI Check-in access token of the service account used for deployments:
# cached token, then EGI_ACCESS_TOKEN, then a refresh with EGI_REFRESH_ACCESS_TOKEN.
module Checkin
  class ServiceAccountToken < ApplicationService
    class Error < StandardError
    end

    SCOPE = "openid email profile voperson_id eduperson_entitlement"

    def initialize(config: Rails.application.config.deployable_services.with_indifferent_access[:authentication])
      super()
      @config = config
    end

    def call
      cached_token || env_token || refreshed_token ||
        raise(Error, "No EGI access token available. Set EGI_ACCESS_TOKEN or EGI_REFRESH_ACCESS_TOKEN.")
    end

    private

    def cached_token
      Rails.cache.read(@config[:token_cache_key])
    end

    def env_token
      ENV.fetch("EGI_ACCESS_TOKEN", nil).presence
    end

    def refreshed_token
      refresh_token = ENV.fetch("EGI_REFRESH_ACCESS_TOKEN", nil)
      return if refresh_token.blank?

      token = request_token(refresh_token)
      Rails.cache.write(@config[:token_cache_key], token, expires_in: @config[:token_cache_expiry_minutes].minutes)
      token
    rescue Faraday::Error, KeyError => e
      Rails.logger.error "Failed to refresh EGI access token: #{e.class}: #{e.message}"
      nil
    end

    def request_token(refresh_token)
      response =
        connection.post(
          @config[:refresh_token_url],
          grant_type: "refresh_token",
          refresh_token: refresh_token,
          client_id: @config[:client_id],
          scope: SCOPE
        )
      response.body.fetch("access_token")
    end

    def connection
      Faraday.new do |conn|
        conn.request :url_encoded
        conn.response :raise_error
        conn.response :json
      end
    end
  end
end
