# frozen_string_literal: true

require "stomp"
require "json"
require "yaml"
require "sentry-ruby"

class Jms::Subscriber
  include ConfigLoaderHelper

  CONFIG_SCHEMA = {
    type: "object",
    properties: {
      subscriptions: {
        type: "array",
        items: {
          type: "object",
          properties: {
            client_name: {
              type: "string"
            },
            login: {
              type: "string"
            },
            password: {
              type: "string"
            },
            host: {
              type: "string"
            },
            topic: {
              type: "string"
            },
            mp_db_events_destination: {
              type: "string"
            },
            user_actions_destination: {
              type: "string"
            },
            ssl_enabled: {
              type: "boolean"
            },
            port: {
              type: "integer"
            },
            virtual_host: {
              type: "string"
            },
            heart_beat: {
              type: "string"
            },
            stomp_version: {
              type: "string"
            },
            subscription_name: {
              type: "string"
            },
            connect_timeout: {
              type: "integer"
            },
            max_reconnect_attempts: {
              type: "integer"
            },
            reconnect_delay: {
              type: "integer"
            },
            token: {
              type: "string"
            },
            topics: {
              type: "array",
              items: {
                type: "string"
              }
            }
          }
        }
      }
    }
  }.freeze

  class ConnectionError < StandardError
    def initialize(msg)
      super
      Sentry.capture_exception(self)
    end
  end

  def initialize(config_file_path = nil, logger: Logger.new("#{Rails.root}/log/jms.log"))
    @logger = logger
    @config_file_path = config_file_path
    @config = load_config(default_config: :stomp_subscriber)
    @clients = {}
    @subscription_threads = []
    $stdout.sync = true
  end

  def run
    log "Starting JMS subscriber with #{@config[:subscriptions]&.length || 0} subscriptions"

    return log "No subscriptions configured" if @config[:subscriptions].blank?

    test_all_connections

    @config[:subscriptions].each_with_index do |subscription, index|
      @subscription_threads << Thread.new do
        Thread.current.name = "JMS-Sub-#{index}"
        subscribe_to_topics(subscription)
      end
    end

    log "All subscription threads started, waiting for completion..."
    @subscription_threads.each(&:join)
  end

  def stop
    log "Stopping JMS subscriber"
    @clients.each do |key, client|
      log "Closing client: #{key}"
      client.close if client.open?
    rescue StandardError => e
      log "Error closing client #{key}: #{e.message}"
    end
    @subscription_threads.each(&:kill)
  end

  private

  def test_all_connections
    log "Testing all connections before starting subscriptions..."

    @config[:subscriptions].each_with_index do |subscription, index|
      server_key = generate_server_key(subscription)
      log "Testing connection #{index + 1}: #{server_key}"

      begin
        test_client = create_test_client(subscription)
        if test_client.open?
          log "✓ Connection test successful for #{server_key}"
          test_client.close
        else
          raise ConnectionError, "Test connection failed for #{server_key}"
        end
      rescue StandardError => e
        log "✗ Connection test failed for #{server_key}: #{e.message}"
        raise ConnectionError, "Cannot connect to #{server_key}: #{e.message}"
      end
    end

    log "All connection tests passed!"
  end

  def create_test_client(config)
    client_config = build_client_config(config)
    client_config[:connect_timeout] = 10
    client_config[:max_reconnect_attempts] = 2

    Stomp::Client.new(client_config)
  end

  def subscribe_to_topics(subscription_config)
    server_key = generate_server_key(subscription_config)

    begin
      client = get_or_create_client(server_key, subscription_config)

      raise ConnectionError, "Failed to establish connection to #{server_key}" unless client.open?

      log "Successfully connected to #{server_key}"

      topics = subscription_config[:topics] || [subscription_config[:topic]].compact

      if topics.empty?
        log "Warning: No topics configured for #{server_key}"
        return
      end

      topics.each { |topic| subscribe_to_topic(client, topic, subscription_config) }

      if client.connection_frame&.command == Stomp::CMD_ERROR
        raise ConnectionError, "Connection error: #{client.connection_frame.body}"
      end

      log "All subscriptions active for #{server_key}, entering message loop..."
      client.join
    rescue StandardError => e
      @logger.error("Error in subscription thread for #{server_key}: #{e.message}")
      @logger.error("Backtrace: #{e.backtrace.join("\n")}")
      Sentry.capture_exception(e)

      sleep 5
      retry_count = Thread.current[:retry_count] || 0
      if retry_count < 3
        Thread.current[:retry_count] = retry_count + 1
        log "Retrying subscription for #{server_key} (attempt #{retry_count + 1}/3)"
        sleep 10
        retry
      else
        log "Max retry attempts reached for #{server_key}, giving up"
      end
    end
  end

  def subscribe_to_topic(client, topic, config)
    destination = "/topic/#{topic}.>"
    subscription_name = config[:subscription_name] || "mpSubscription"

    log "Subscribing to topic: #{topic} on #{config[:host]}:#{config[:port] || 61_613}"

    client.subscribe(destination, { ack: "client-individual", "activemq.subscriptionName": subscription_name }) do |msg|
      log "Message arrived for topic: #{topic}"
      begin
        process_message(msg, config)
        client.ack(msg)
      rescue StandardError => e
        log "Error processing message: #{e.message}"
        client.unreceive(msg)
        error_block(msg, e, topic)
      end
    end
  end

  def process_message(msg, config)
    eosc_registry_base_url = config[:eosc_registry_base_url] || @config[:eosc_registry_base_url]
    token = config[:token] || @config[:token]

    Jms::ManageMessage.call(msg, eosc_registry_base_url, @logger, token)
  end

  def get_or_create_client(server_key, config)
    return @clients[server_key] if @clients[server_key]&.open?

    client_config = build_client_config(config)
    log "Creating new client for server: #{server_key}"
    log "Client configuration: #{sanitize_config_for_log(client_config)}"

    @clients[server_key] = Stomp::Client.new(client_config)
  end

  def sanitize_config_for_log(config)
    safe_config = config.deep_dup
    safe_config[:hosts].each { |host| host[:passcode] = "[HIDDEN]" if host[:passcode] }
    safe_config
  end

  def generate_server_key(config)
    "#{config[:host]}:#{config[:port] || 61_613}"
  end

  def build_client_config(config)
    {
      hosts: [
        {
          login: config[:login],
          passcode: config[:password],
          host: config[:host],
          port: (config[:port] || 61_613).to_i,
          ssl: config[:ssl_enabled] || false
        }
      ],
      connect_timeout: (config[:connect_timeout] || 15).to_i,
      max_reconnect_attempts: (config[:max_reconnect_attempts] || 5).to_i,
      reconnect_delay: (config[:reconnect_delay] || 5).to_i,
      connect_headers: {
        "client-id": config[:client_name] || "jms_subscriber",
        "heart-beat": config[:heart_beat] || "0,20000",
        "accept-version": config[:stomp_version] || "1.2",
        host: config[:virtual_host] || "localhost"
      },
      logger: @logger
    }
  end

  def error_block(msg, error, topic)
    @logger.error("Error occurred while processing message from topic #{topic}:")
    @logger.error("Message: #{msg}")
    @logger.error("Error: #{error.message}")
    @logger.error("Backtrace: #{error.backtrace.join("\n")}")
    Sentry.capture_exception(error)
  end

  def log(msg)
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    @logger.info("[#{timestamp}] #{msg}")
    puts "[#{timestamp}] #{msg}" if Rails.env.development?
  end

  def config_schema
    CONFIG_SCHEMA
  end
end
