# frozen_string_literal: true

require "net/http"

class RaidProject::GetRaids
  def initialize(token)
    @base_url = "https://api.raid.surf.nl/raid/"
    @headers = { "Authorization" => "Bearer #{token}" }
  end

  def call
    response = Faraday.get(@base_url, {}, @headers)
    { status: response.status, data: ActiveSupport::JSON.decode(response.body) }
  rescue StandardError
    Sentry.capture_message("Raid get list responded with #{response.status}. \n #{response.body}")
    { status: response.status, data: [] }
  end
end
