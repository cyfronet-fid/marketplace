# frozen_string_literal: true

class Users::IntrospectAccessToken < ApplicationService
  Result = Struct.new(:success, :active, :entitlements, keyword_init: true)

  def initialize(token, client_options: Users::CheckinConfig.client_options)
    super()
    @token = token
    @client_options = client_options
  end

  def call
    connection = Faraday.new { |conn| conn.basic_auth(@client_options[:identifier], @client_options[:secret]) }

    response =
      connection.post(Users::CheckinConfig.introspection_url(@client_options)) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = { token: @token }.map { |k, v| "#{k}=#{v}" }.join("&")
      end

    unless response.success?
      Rails.logger.warn("Token introspection failed: #{response.status}")
      return Result.new(success: false, active: false, entitlements: [])
    end

    body = JSON.parse(response.body)
    Result.new(success: true, active: body["active"], entitlements: Array(body["entitlements"]))
  rescue Faraday::Error, JSON::ParserError => e
    Rails.logger.error("Invalid introspection response: #{e.message}")
    Result.new(success: false, active: false, entitlements: [])
  end
end
