# frozen_string_literal: true

require "net/http"

class RaidProject::RaidLogin
  def initialize
    @url = "https://auth.raid.surf.nl/realms/raid/protocol/openid-connect/token"
  end

  def call
    response =
      Faraday.post(@url) do |req|
        req.headers = headers
        req.body = URI.encode_www_form(data)
      end
    response_body = JSON.parse(response.body)
    response_body["access_token"]
  rescue StandardError
    Sentry.capture_message("Raid login responded with #{response.status}. \n #{response.body}")
    []
  end

  private

  def data
    {
      client_id: Rails.application.credentials.raid[:client_id],
      username: Rails.application.credentials.raid[:username],
      password: Rails.application.credentials.raid[:password],
      grant_type: "password"
    }
  end

  def headers
    { "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json" }
  end
end
