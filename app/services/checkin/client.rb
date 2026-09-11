# frozen_string_literal: true

require "uri"

module Checkin
  class Client
    DEFAULT_TIMEOUT = 10
    DEFAULT_OPEN_TIMEOUT = 5

    def initialize(timeout: DEFAULT_TIMEOUT, open_timeout: DEFAULT_OPEN_TIMEOUT)
      @timeout = timeout
      @open_timeout = open_timeout
    end

    def introspect(access_token)
      connection.post(oidc_config.raw["introspection_endpoint"]) do |req|
        req.body = URI.encode_www_form(token: access_token)
        req.headers.merge!(headers)
      end
    end

    def refresh_token(refresh_token)
      connection.post(oidc_config.raw["token_endpoint"]) do |req|
        req.body = URI.encode_www_form(grant_type: "refresh_token", refresh_token: refresh_token)
        req.headers.merge!(headers)
      end
    end

    private

    attr_reader :timeout, :open_timeout

    def connection
      @connection ||=
        Faraday.new do |conn|
          conn.basic_auth(client_options[:identifier], client_options[:secret])
          conn.options.timeout = timeout
          conn.options.open_timeout = open_timeout
          conn.adapter Faraday.default_adapter
        end
    end

    def headers
      { "Content-Type" => "application/x-www-form-urlencoded" }
    end

    def oidc_config
      @oidc_config ||= OmniAuth::Strategies::OpenIDConnect.new(nil, provider.options).config
    end

    def client_options
      provider.options[:client_options]
    end

    def provider
      Devise.omniauth_configs[:checkin]
    end
  end
end
