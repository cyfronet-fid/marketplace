# frozen_string_literal: true

require "stomp"
require "json"
require "raven"

module Jms
  class Subscriber
    class ResourceParseError < StandardError; end
    class ConnectionError < StandardError
      def initialize(msg)
        Raven.capture_exception(msg)
        super(msg)
      end
    end

    def initialize(topic, login, pass,  host,
                   client_name, eic_base_url,
                   client: Stomp::Client,
                   logger: Logger.new("#{Rails.root}/log/jms.log"))
      @logger = logger
      $stdout.sync = true
      @client = client.new(conf_hash(login, pass, host, client_name))
      log "Parameters: #{conf_hash(login, pass, host, client_name)}"
      @destination = topic
      @eic_base_url = eic_base_url
    end

    def run
      log "Start subscriber on destination: #{@destination}"
      @client.subscribe("/topic/#{@destination}.>", { "ack": "client-individual", "activemq.subscriptionName": "mpSubscription" }) do |msg|
        log "Arrived message"
        Jms::ManageMessage.new(msg, @eic_base_url, @logger).call
        @client.ack(msg)
      rescue StandardError => e
        @client.unreceive(msg)
        error_block(msg, e)
      end

      raise ConnectionError.new("Connection failed!!") unless @client.open?()
      raise ConnectionError.new("Connect error: #{@client.connection_frame().body}") if @client.connection_frame().command == Stomp::CMD_ERROR

      @client.join
    end

    private
      def error_block(msg, e)
        @logger.error("Error occured while processing message:\n #{msg}")
        @logger.error(e)
        Raven.capture_exception(e)
        abort(e.full_message)
      end

      def conf_hash(login, pass, host_des, client_name)
        {
          hosts: [
            {
              login: login,
              passcode: pass,
              host:  "#{host_des}",
              port: 61613,
              ssl: false
            }
          ],
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
