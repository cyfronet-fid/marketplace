# frozen_string_literal: true

require "sentry-ruby"
require "erb"

class Ess::Update < ApplicationService
  class Error < StandardError
  end

  def initialize(payload)
    super()
    @payload = payload
    @config = Mp::Application.config_for(:ess_update)
    @link = "#{@config["url"]}?data_type=#{ERB::Util.url_encode(@payload["data_type"])}&action=#{@payload["action"]}"
  end

  def call
    Rails.logger.info("Updating on #{@link} ESS with payload: #{@payload["data"].to_json}")
    @config["enabled"] ? update : Rails.logger.info("Ess::Update disabled, enable with ESS_UPDATE_ENABLED=true")
  end

  private

  def update
    response =
      Faraday.post(@link, @payload["data"].to_json, headers) { |conn| conn.options.timeout = @config["timeout"] }
    Rails.logger.info("Response (status #{response.status}): #{response.body}")
    if response.status >= 400
      msg = "ESS::Update returned #{response.status}\nPayload:\n#{@payload}\nResponse:\n#{response.body}"
      Rails.logger.warn(msg)
      ::Sentry.capture_message(msg)
    end
  rescue Faraday::Error => e
    Rails.logger.warn("Cannot update due to: #{e.full_message}. Payload: #{@payload}")
    ::Sentry.capture_exception(e)
    raise Error, "Cannot update", cause: e
  end

  def headers
    { "Content-Type": "application/json", Accept: "application/json" }
  end
end
