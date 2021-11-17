# frozen_string_literal: true

require "stomp"
require "json"
require "sentry-ruby"

module Jms
  class Publisher
    class ConnectionError < StandardError
      def initialize(msg)
        super(msg)
        Sentry.capture_exception(self)
      end
    end

    def publish(msg)
      unless ENV["STOMP_PUBLISHER_ENABLED"]
        return
      end

      queue_configuration = Config::StompPublisherQueue.new
      connection_configuration = Config::StompConnection.new

      queue_configuration.logger.info "Publish to the topic: #{queue_configuration.topic}"
      queue_configuration.logger.info "Parameters: #{connection_configuration.to_hash}"

      connection = Stomp::Connection.new(connection_configuration.to_hash)

      # IMPORTANT!!!
      # Sidekiq has known issue of cutting message to max 256 chars
      # To preserve such behaviour params:
      # - 'persistent'
      # - 'suppress_content_length'
      # need to be set
      headers = {
        "ack": "client-individual",
        "persistent": true,
        "suppress_content_length": true,
        "content-type": "application/json"
      }
      topic = "/topic/#{queue_configuration.topic}.>"
      connection.publish(topic, msg.to_json, headers)

      unless @connection.open?
        raise ConnectionError.new("Connection failed!!")
      end
      command_error = @connection.connection_frame.command == Stomp::CMD_ERROR
      if command_error
        raise ConnectionError.new("Connection error: #{@connection.connection_frame.body}")
      end

      connection.disconnect
    rescue Jms::ManageMessage::ResourceParseError,
      Jms::ManageMessage::WrongMessageError,
      JSON::ParserError,
      StandardError => e
      queue_configuration.logger.error("Error occurred while processing message:\n #{msg}")
      queue_configuration.logger.error(e)
      Sentry.capture_exception(e)
      abort(e.full_message)
    end
  end
end
