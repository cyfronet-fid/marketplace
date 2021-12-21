# frozen_string_literal: true

require "stomp"
require "json"
require "sentry-ruby"

module Jms
  class Subscriber
    class ConnectionError < StandardError
      def initialize(msg)
        super(msg)
        Sentry.capture_exception(self)
      end
    end

    def initialize(
      topic,
      login,
      pass,
      host,
      client_name,
      eosc_registry_base_url,
      ssl_enabled,
      token = nil,
      client: Stomp::Client,
      logger: Logger.new("#{Rails.root}/log/jms.log")
    )
      @logger = logger
      $stdout.sync = true
      @client = client.new(conf_hash(login, pass, host, client_name, ssl_enabled))
      log "Parameters: #{conf_hash(login, pass, host, client_name, ssl_enabled)}"
      @destination = topic
      @eosc_registry_base_url = eosc_registry_base_url
      @token = token
    end

    def run
      log "Start subscriber on destination: #{@destination}"
      @client.subscribe(
        "/topic/#{@destination}.>",
        { "ack": "client-individual", "activemq.subscriptionName": "mpSubscription" }
      ) do |msg|
        log "Arrived message"
        Jms::ManageMessage.new(msg, @eosc_registry_base_url, @logger, @token).call
        @client.ack(msg)
      rescue Jms::ManageMessage::ResourceParseError,
             Jms::ManageMessage::WrongMessageError,
             JSON::ParserError,
             StandardError => e
        @client.unreceive(msg)
        error_block(msg, e)
      end

      raise ConnectionError, "Connection failed!!" unless @client.open?
      if @client.connection_frame.command == Stomp::CMD_ERROR
        raise ConnectionError, "Connection error: #{@client.connection_frame.body}"
      end

      @client.join
    end

    private

    def error_block(msg, e)
      @logger.error("Error occurred while processing message:\n #{msg}")
      @logger.error(e)
      Sentry.capture_exception(e)
      abort(e.full_message)
    end

    def conf_hash(login, pass, host_des, client_name, ssl)
      {
        hosts: [{ login: login, passcode: pass, host: host_des, port: 61_613, ssl: ssl }],
        connect_timeout: 5,
        max_reconnect_attempts: 5,
        connect_headers: {
          "client-id": client_name,
          "heart-beat": "0,20000",
          "accept-version": "1.2",
          "host": "localhost"
        }
      }
    end

    def log(msg)
      @logger.info(msg)
    end
  end
end
