# frozen_string_literal: true

require "faraday_middleware"

class Importers::Token
  class RequestError < StandardError
    def initialize(
      msg = "" \
            "Access Token can't be received. Cause can be: \n" \
            "- expired/missing IMPORTER_AAI_REFRESH_TOKEN (refresh-token grant), " \
            "or a wrong IMPORTER_AAI_CLIENT_SECRET (client-credentials grant) \n" \
            "- incorrect IMPORTER_AAI_CLIENT_ID for which the credential was issued \n" \
            "- incorrect IMPORTER_AAI_HOST/CHECKIN_HOST for which the credential was issued\n"
    )
      super
    end
  end

  AAI_BASE_URL = "https://#{ENV["IMPORTER_AAI_BASE_URL"] || ENV["CHECKIN_HOST"] || "aai.eosc-portal.eu"}".freeze
  AAI_TOKEN_PATH = "/auth/realms/core/protocol/openid-connect/token"
  REFRESH_TOKEN = ENV.fetch("IMPORTER_AAI_REFRESH_TOKEN", nil)
  CLIENT_SECRET = ENV.fetch("IMPORTER_AAI_CLIENT_SECRET", nil)

  CLIENT_ID =
    ENV["IMPORTER_AAI_CLIENT_ID"] || ENV["CHECKIN_IDENTIFIER"] || Rails.application.credentials.checkin[:identifier]

  def initialize(faraday: Faraday)
    @faraday = faraday
  end

  def receive_token
    response = @faraday.post("#{AAI_BASE_URL}#{AAI_TOKEN_PATH}", grant_params)
    raise RequestError if response.blank? || !response.body&.include?("access_token")

    JSON.parse(response.body)["access_token"]
  end

  private

  # No manually-provisioned refresh token to rotate when a client secret is
  # configured - ported from whitelabel-marketplace's automatic import token
  # retrieval (ADR-0001 whitelabel feature audit, gap #4). Selected by
  # credential presence, same as the rest of this class's ENV.fetch pattern,
  # rather than a separate on/off flag.
  def grant_params
    if CLIENT_SECRET.present?
      { grant_type: "client_credentials", client_id: CLIENT_ID, client_secret: CLIENT_SECRET }
    else
      { grant_type: "refresh_token", refresh_token: REFRESH_TOKEN, client_id: CLIENT_ID }
    end
  end
end
