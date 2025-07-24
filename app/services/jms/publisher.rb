# frozen_string_literal: true

class Jms::Publisher
  class ConnectionError < StandardError
  end

  class PublishError < StandardError
  end

  # rubocop:disable Metrics/ParameterLists
  def initialize(topic, login, pass, host, ssl_enabled, logger)
    # rubocop:enable Metrics/ParameterLists
    @logger = logger

    conf_hash_res = conf_hash(login, pass, host, ssl_enabled)
    @client = Stomp::Client.new(conf_hash_res)
    @topic = topic

    verify_connection!
  end

  def publish(msg)
    @logger.debug("Publishing to #{@topic}, message #{msg}")
    @client.publish(msg_destination, msg, msg_headers)
  rescue RuntimeError => e
    raise PublishError, "Error when publishing a message", cause: e
  end

  def close
    @client.close
  end

  private

  def conf_hash(login, pass, host, ssl)
    {
      hosts: [{ login: login, passcode: pass, host: host, port: 61_613, ssl: ssl }],
      connect_timeout: 5,
      max_reconnect_attempts: 5,
      connect_headers: {
        "accept-version": "1.2", # mandatory
        host: "localhost" # mandatory
      }
    }
  end

  def verify_connection!
    raise ConnectionError, "Connection failed!!" unless @client.open?
    if @client.connection_frame.command == Stomp::CMD_ERROR
      raise ConnectionError, "Connection error: #{@client.connection_frame.body}"
    end
  end

  def msg_destination
    "/topic/#{@topic}"
  end

  def msg_headers
    {
      persistent: true,
      # Without suppress_content_length ActiveMQ interprets the message as a BytesMessage, instead of a TextMessage.
      # See https://github.com/stompgem/stomp/blob/v1.4.10/lib/connection/netio.rb#L245
      # and https://activemq.apache.org/stomp.html.
      suppress_content_length: true,
      "content-type": "application/json"
    }
  end
end
