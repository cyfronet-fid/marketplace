# frozen_string_literal: true

module Ams
  class Client
    ACK_DEADLINE = 10
    DEFAULT_TIMEOUT = 10
    DEFAULT_OPEN_TIMEOUT = 5
    MAX_MESSAGES = 10

    def initialize(timeout: DEFAULT_TIMEOUT, open_timeout: DEFAULT_OPEN_TIMEOUT)
      @timeout = timeout
      @open_timeout = open_timeout
    end

    def pull(subscription_name, max_messages: MAX_MESSAGES)
      pull_path = "#{config.subscriptions_path}/#{subscription_name}:pull"

      connection.post(pull_path) do |req|
        req.body = { maxMessages: max_messages.to_s, returnImmediately: "true" }
        req.headers.merge!(headers)
      end
    end

    def acknowledge(subscription_name, ack_ids:)
      acknowledge_path = "#{config.subscriptions_path}/#{subscription_name}:acknowledge"

      connection.post(acknowledge_path) do |req|
        req.body = { ackIds: ack_ids }
        req.headers.merge!(headers)
      end
    end

    def create_subscription(topic_name)
      topic = "#{config.topics_path}/#{topic_name}".delete_prefix("/v1/")
      subscription_path = build_subscription_path(topic_name)

      connection.put(subscription_path) do |req|
        req.body = { topic: topic, ackDeadlineSeconds: ACK_DEADLINE }
        req.headers.merge!(headers)
      end
    end

    def delete_subscription(topic_name)
      subscription_path = build_subscription_path(topic_name)

      connection.delete(subscription_path) do |req|
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

    def build_subscription_path(topic_name)
      subscription_name = [config.subscription_prefix, topic_name].compact.join("-")

      "#{config.subscriptions_path}/#{subscription_name}"
    end

    def headers
      { "x-api-key" => config.token }
    end
  end
end
