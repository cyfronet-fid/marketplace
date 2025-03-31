# frozen_string_literal: true

require "net/http"

class RaidProject::UpdateRaid
  def initialize(raid_project, token, pid)
    @raid_project = raid_project
    @url = "https://api.raid.surf.nl/raid/#{pid}"
    @token = token
  end

  def call
    response = Faraday.put(@url, @raid_project.to_json, headers)
    { status: response.status, data: ActiveSupport::JSON.decode(response.body) }
  rescue StandardError
    Sentry.capture_message("Raid update responded with #{response.status}. \n #{response.body}")
    { status: response.status, data: {} }
  end

  private

  def headers
    { "Content-Type": "application/json", Accept: "application/json", Authorization: "Bearer #{@token}" }
  end
end
