# frozen_string_literal: true

require "net/http"

class RaidProject::PostRaid
  def initialize(raid_project, token)
    @raid_project = raid_project
    @url = "https://api.raid.surf.nl/raid/"
    @token = token
  end

  def call
    response = Faraday.post(@url, @raid_project.to_json, headers)
    { status: response.status, data: ActiveSupport::JSON.decode(response.body) }
  rescue StandardError
    Sentry.capture_message("Raid post responded with #{response.status}. \n #{response.body}")
    { status: response.status, data: {} }
  end

  private

  def headers
    { "Content-Type": "application/json", Accept: "application/json", Authorization: "Bearer #{@token}" }
  end
end
