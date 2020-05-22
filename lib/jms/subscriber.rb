# frozen_string_literal: true

require "stomp"
require "json"
require "nori"
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

    def initialize(topic, login, pass,  host, eic_base_url,
                   client: Stomp::Client,
                   logger: Logger.new("#{Rails.root}/log/jms.log"))
      $stdout.sync = true
      @client = client.new(conf_hash(login, pass, host))
      @destination = topic
      @eic_base_url = eic_base_url
      @logger = logger
    end

    def run
      log "Start subscriber on destination: #{@destination}"
      parser = Nori.new(strip_namespaces: true)

      @client.subscribe("/topic/#{@destination}.>", { "ack": "client-individual", "activemq.subscriptionName": "mpSubscription" }) do |msg|
        log "Arrived message"
        body = JSON.parse(msg.body)
        resource = parser.parse(body["resource"])
        log "rerource:\n #{resource}"

        raise ResourceParseError.new("Cannot parse resource") if resource.empty?

        case body["resourceType"]
        when "infra_service"
          if resource["infraService"]["latest"]
            Service::PcCreateOrUpdate.new(resource["infraService"], @eic_base_url).call
          end
        when "provider"
          if resource["provider"]["active"]
            Provider::PcCreateOrUpdate.new(resource["provider"]).call
          end
        else
          log msg
        end
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
        log "Error occured while processing message:\n #{msg}"
        log e
        Raven.capture_exception(e)
        abort(e.full_message)
      end

      def conf_hash(login, pass, host_des)
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
            "client-id": "MPClientTest",
            "heart-beat": "0,20000",
            "accept-version": "1.2",
            "host": "localhost"
          }
        }
      end

      def log(msg)
        puts msg
        @logger.info(msg)
      end
  end
end
