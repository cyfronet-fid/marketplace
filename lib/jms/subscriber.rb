# frozen_string_literal: true

require "stomp"
require "json"
require "nori"
require "raven"

module Jms
  class Subscriber
    class ResourceParseError < StandardError; end

    def initialize(topic, login, pass,  host, eic_base_url)
      $stdout.sync = true
      @client = Stomp::Client.new(conf_hash(login, pass, host))
      @destination = topic
      @eic_base_url = eic_base_url
    end

    def run
      puts "Start subscriber on destination: #{@destination}"
      parser = Nori.new(strip_namespaces: true)

      begin
        @client.subscribe("/topic/#{@destination}.>", { "ack": "client-individual", "activemq.subscriptionName": "mpSubscription" }) do |msg|
          puts "Arrived message"

          body = JSON.parse(msg.body)
          resource = parser.parse(body["resource"])
          puts "rerource: ", resource

          raise ResourceParseError.new("Cannot parse resource") if resource.empty?

          case body["resourceType"]
          when "infra_service"
            if resource["infraService"]["latest"]
              Service::PcCreateOrUpdate.new(resource["infraService"], @eic_base_url).call
            end
          when "provider"
            if resource["provider"]["active"]
              Provider::PcCreateOrUpdate.new(resource).call
            end
          else
            puts msg
          end
          @client.ack(msg)
        end
        raise "Connection failed!!" unless @client.open?()
        raise "Connect error: #{@client.connection_frame().body}" if @client.connection_frame().command == Stomp::CMD_ERROR

        @client.join
      rescue StandardError => e
        @client.unreceive(msg)
        error_block(msg, e)
      end
    end

    private
      def error_block(msg, e)
        puts "#{Time.now.strftime("%c")}: Error occured while processing message:\n #{msg}"
        puts e
        Raven.capture_exception(e)
        abort(e)
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
            "client-id": "MPClient",
            "heart-beat": "0,20000",
            "accept-version": "1.2",
            "host": "localhost"
          },
          logger: -> (msg) { puts msg }
        }
      end
  end
end
