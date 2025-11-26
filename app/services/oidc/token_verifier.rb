# frozen_string_literal: true

require "singleton"
require "net/http"
require "uri"
require "json"

module Oidc
  class TokenVerifier
    include Singleton

    class VerificationError < StandardError
    end

    CACHE_KEY_JWKS = "oidc_jwks_cache_v1"
    CACHE_TTL = 10.minutes

    def initialize
      @issuer = Devise.omniauth_configs[:checkin].options[:issuer]
      raise VerificationError, "OIDC issuer not configured (OIDC_ISSUER_URI/CHECKIN_ISSUER_URI)" if @issuer.blank?

      @audience = ENV["OIDC_AUDIENCE"].presence || ENV["CHECKIN_IDENTIFIER"].presence
      @accepted_audiences = (ENV["OIDC_ACCEPTED_AUDIENCES"] || "").split(",").map(&:strip).reject(&:blank?)
      @accept_azp = (ENV.fetch("OIDC_ACCEPT_AZP", "true").to_s.downcase == "true")
      @verify_aud = (ENV.fetch("OIDC_VERIFY_AUD", "true").to_s.downcase == "true")
    end

    # Verifies the JWT and returns decoded claims (Hash with string keys)
    def verify!(token)
      options = {
        algorithms: [ENV.fetch("OIDC_JWT_ALG", "RS256")],
        jwks: jwk_set,
        iss: @issuer,
        verify_iss: true,
        verify_expiration: true,
        verify_not_before: true
      }

      # We perform custom audience validation to support Keycloak tokens where
      # `aud` can be "account" and client_id is provided in `azp`.
      options[:verify_aud] = false

      decoded, = JWT.decode(token, nil, true, options)

      validate_audience!(decoded) if @verify_aud
      decoded
    rescue JWT::DecodeError => e
      raise VerificationError, e.message
    end

    private

    def jwk_set
      json = Rails.cache.fetch(CACHE_KEY_JWKS, expires_in: CACHE_TTL) { fetch_jwks_json }
      JWT::JWK::Set.new(json)
    end

    def fetch_jwks_json
      uri = URI(jwks_uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri)
      res = http.request(request)
      raise VerificationError, "Cannot fetch JWKS (#{res.code})" unless res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)
    rescue StandardError => e
      raise VerificationError, "JWKS fetch failed: #{e.message}"
    end

    def jwks_uri
      explicit = Devise.omniauth_configs[:checkin].options[:token_endpoint]
      return explicit if explicit&.start_with?("http")
      return "#{explicit}" if explicit.present? && explicit.start_with?("/") && issuer_host.present?

      # Discover from OIDC well-known configuration
      discover_well_known["jwks_uri"] || raise(VerificationError, "jwks_uri not found in discovery")
    end

    def discover_well_known
      Rails
        .cache
        .fetch("oidc_discovery_#{@issuer}", expires_in: 30.minutes) do
          uri = URI(well_known_uri)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == "https"
          # Disable SSL verification to avoid failures with incomplete/invalid cert chains or CRLs
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
          request = Net::HTTP::Get.new(uri)
          res = http.request(request)
          raise VerificationError, "OIDC discovery failed (#{res.code})" unless res.is_a?(Net::HTTPSuccess)
          JSON.parse(res.body)
        end
    rescue StandardError => e
      raise VerificationError, "OIDC discovery error: #{e.message}"
    end

    def well_known_uri
      if @issuer.end_with?("/")
        URI.join(@issuer, ".well-known/openid-configuration").to_s
      else
        URI.join(@issuer + "/", ".well-known/openid-configuration").to_s
      end
    end

    def issuer_host
      URI(@issuer).host
    rescue StandardError
      nil
    end

    def validate_audience!(claims)
      expected = []
      expected << @audience if @audience.present?
      expected.concat(@accepted_audiences) if @accepted_audiences.any?

      # If nothing is configured, skip audience validation silently
      return true if expected.empty?

      aud_claim = claims["aud"]
      aud_list =
        case aud_claim
        when Array
          aud_claim.compact
        when String
          [aud_claim]
        else
          []
        end

      valid = expected.intersect?(aud_list)

      if !valid && @accept_azp
        azp = claims["azp"].to_s
        valid = expected.include?(azp)
      end

      return true if valid

      received = aud_list.any? ? aud_list.join(",") : (claims["azp"] || "<none>")
      raise VerificationError, "Invalid audience. Expected #{expected.join(", ")}, received #{received}"
    end
  end
end
