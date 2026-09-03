# frozen_string_literal: true

class Users::RefreshAccessToken < ApplicationService
  Result = Struct.new(:success, :access_token, :refresh_token, keyword_init: true)

  def initialize(refresh_token, client_options: Users::CheckinConfig.client_options)
    super()
    @refresh_token = refresh_token
    @client_options = client_options
  end

  def call
    return Result.new(success: false) if @refresh_token.blank?

    connection = Faraday.new { |conn| conn.basic_auth(@client_options[:identifier], @client_options[:secret]) }

    response =
      connection.post(Users::CheckinConfig.token_url(@client_options)) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"

        req.body = {
          grant_type: "refresh_token",
          refresh_token: @refresh_token
        }.map { |k, v| "#{k}=#{v}" }.join("&")
      end

    unless response.success?
      Rails.logger.warn("Token refresh failed: #{response.status}")
      return Result.new(success: false)
    end

    body = JSON.parse(response.body)
    Result.new(success: true, access_token: body["access_token"], refresh_token: body["refresh_token"])
  rescue Faraday::Error, JSON::ParserError => e
    Rails.logger.warn("Token refresh failed: #{e.message}")
    Result.new(success: false)
  end
end
