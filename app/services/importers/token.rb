# frozen_string_literal: true

require "faraday_middleware"

class Importers::Token
  class RequestError < StandardError
    def initialize(
      msg = "" \
        "Access Token can't be received from a refresh token. " \
        "Cause can be: \n" \
        "- expired/missing REFRESH_TOKEN \n" \
        "- incorrect IMPORTER_AAI_CLIENT_ID for which the refresh token was generated \n" \
        "- incorrect IMPORTER_AAI_HOST/CHECKIN_HOST for which the refresh token was generated\n"
    )
      super
    end
  end

  AAI_BASE_URL = "https://#{ENV["IMPORTER_AAI_BASE_URL"] || ENV["CHECKIN_HOST"] || "aai.eosc-portal.eu"}".freeze
  AAI_TOKEN_PATH = "/auth/realms/core/protocol/openid-connect/token"
  REFRESH_TOKEN = ENV.fetch("IMPORTER_AAI_REFRESH_TOKEN", nil)

  CLIENT_ID =
    ENV["IMPORTER_AAI_CLIENT_ID"] || ENV["CHECKIN_IDENTIFIER"] || Rails.application.credentials.checkin[:identifier]

  def initialize(faraday: Faraday)
    @faraday = faraday
  end

  def receive_token
    data = { grant_type: "refresh_token", refresh_token: REFRESH_TOKEN, client_id: CLIENT_ID }
    response = @faraday.post("#{AAI_BASE_URL}#{AAI_TOKEN_PATH}", data)
    raise RequestError if response.blank? || !response.body&.include?("access_token")
    JSON.parse(response.body)["access_token"]
  end
end
