# frozen_string_literal: true

class Ams::Client
  DEFAULT_TIMEOUT = 10
  DEFAULT_OPEN_TIMEOUT = 5
  MAX_MESSAGES = 10

  def initialize(timeout: DEFAULT_TIMEOUT, open_timeout: DEFAULT_OPEN_TIMEOUT)
    @timeout = timeout
    @open_timeout = open_timeout
  end

  def pull(subscription_path, max_messages: MAX_MESSAGES)
    pull_path = "#{subscription_path}:pull"

    connection.post(pull_path) do |req|
      req.body = { maxMessages: max_messages.to_s, returnImmediately: "true" }
      req.headers.merge!(headers)
    end
  end

  def acknowledge(subscription_path, ack_ids: [])
    return if ack_ids.blank?

    acknowledge_path = "#{subscription_path}:acknowledge"

    connection.post(acknowledge_path) do |req|
      req.body = { ackIds: ack_ids }
      req.headers.merge!(headers)
    end
  end

  private

  attr_reader :timeout, :open_timeout

  def config
    @config ||= Rails.application.config_for(:ams)
  end

  def connection
    @connection ||=
      Faraday.new(config.base_url) do |conn|
        conn.request :json
        conn.response :json
        conn.ssl.verify = true
        conn.options.timeout = timeout
        conn.options.open_timeout = open_timeout
        conn.adapter Faraday.default_adapter
      end
  end

  def headers
    { "x-api-key" => config.token }
  end
end
