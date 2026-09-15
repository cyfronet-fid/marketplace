# frozen_string_literal: true

require "uri"

class Importers::ClientCredentialsToken
  class ConfigurationError < StandardError
  end

  class RequestError < StandardError
  end

  REQUIRED_ENV = %w[IMPORT_CLIENT_ID IMPORT_CLIENT_SECRET].freeze
  CONFIGURATION_ERROR_MESSAGE =
    "Missing CHECKIN_TOKEN_ENDPOINT or CHECKIN_HOST for import client credentials authentication"

  def self.configured?
    REQUIRED_ENV.all? { |key| ENV[key].present? }
  end

  def self.partially_configured?
    REQUIRED_ENV.any? { |key| ENV[key].present? } && !configured?
  end

  def initialize(faraday: Faraday)
    @faraday = faraday
  end

  def receive_token
    validate_configuration!

    response =
      @faraday.post(
        token_endpoint,
        URI.encode_www_form(
          grant_type: "client_credentials",
          client_id: ENV.fetch("IMPORT_CLIENT_ID"),
          client_secret: ENV.fetch("IMPORT_CLIENT_SECRET")
        ),
        "Content-Type" => "application/x-www-form-urlencoded"
      )

    raise RequestError, "Access token response is empty" if response.blank? || response.body.blank?

    token = JSON.parse(response.body)["access_token"]
    return token if token.present?

    raise RequestError, "Access token response does not include access_token"
  rescue JSON::ParserError
    raise RequestError, "Access token response is not valid JSON"
  rescue Faraday::Error => e
    raise RequestError, "Access token request failed: #{e.message}"
  end

  private

  def validate_configuration!
    if self.class.partially_configured?
      missing = REQUIRED_ENV.select { |key| ENV[key].blank? }.join(", ")
      raise ConfigurationError, "Missing import client credentials: #{missing}"
    end

    return if ENV["CHECKIN_TOKEN_ENDPOINT"].present? && (absolute_token_endpoint? || ENV["CHECKIN_HOST"].present?)

    raise ConfigurationError, CONFIGURATION_ERROR_MESSAGE
  end

  def token_endpoint
    endpoint = ENV.fetch("CHECKIN_TOKEN_ENDPOINT")
    return endpoint if absolute_token_endpoint?

    endpoint = endpoint.delete_prefix("/")
    endpoint = "auth/#{endpoint}" unless endpoint.start_with?("auth/")

    "https://#{ENV.fetch("CHECKIN_HOST")}/#{endpoint}"
  end

  def absolute_token_endpoint?
    ENV.fetch("CHECKIN_TOKEN_ENDPOINT", "").start_with?("http://", "https://")
  end
end
