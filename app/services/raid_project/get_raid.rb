# frozen_string_literal: true

require "net/http"

class RaidProject::GetRaid
  def initialize(token, pid)
    @url = "https://api.raid.surf.nl/raid/#{pid}"
    @headers = { "Authorization" => "Bearer #{token}" }
  end

  def call
    response = Faraday.get(@url, {}, @headers)
    { status: response.status, data: ActiveSupport::JSON.decode(response.body) }
  rescue StandardError
    Sentry.capture_message("Raid get by pid responded with #{response.status}. \n #{response.body}")
    { status: response.status, data: {} }
  end
end
