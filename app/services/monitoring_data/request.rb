# frozen_string_literal: true

require "faraday_middleware"

class MonitoringData::Request < ApplicationService
  def initialize(url, endpoint, faraday: Faraday, access_token: nil, id: nil, start_date: nil, end_date: nil)
    super()
    @url = url
    @endpoint = endpoint
    @access_token = access_token
    @start_date = start_date
    @end_date = end_date
    @id = id
    @conn = api_client_connection(faraday, @access_token)
  end

  def call
    request = @id.blank? ? all : specific
    raise Errno::ECONNREFUSED if request.blank? || request.status != 200
    request
  end

  def all
    @conn.get("#{@url}/#{@endpoint}", { start_time: @start_date, end_time: @end_date, granularity: "monthly" })
  end

  def specific
    @conn.get("#{@url}/#{@endpoint}/id/#{@id}?view=latest")
  end

  def api_client_connection(faraday, authorization_header = nil)
    faraday.new do |f|
      f.request :url_encoded
      f.request :multipart
      f.request :json # encode req bodies as JSON
      f.request :retry # retry transient failures
      f.response :follow_redirects # follow redirects
      f.response :json # decode response bodies as JSON
      f.headers["accept"] = "application/json"
      f.headers["x-api-key"] = authorization_header unless authorization_header.blank?
      f.adapter Faraday.default_adapter
    end
  end
end
