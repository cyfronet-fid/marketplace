# frozen_string_literal: true

class Jms::Publisher
  class ConnectionError < StandardError
    def initialize(msg)
      super(msg)
    end
  end

  def initialize(topic, login, pass, host, client_name, ssl_enabled, logger)
    @logger = logger

    conf_hash_res = conf_hash(login, pass, host, client_name, ssl_enabled)
    @client = Stomp::Client.new(conf_hash_res)
    @topic = topic

    verify_connection!
  end

  def publish(msg)
    @logger.info("Publishing to #{@topic}, message #{msg}")
    @client.publish(msg_destination, msg, msg_headers)
  end

  def close
    @client.close
  end

  private
    def conf_hash(login, pass, host, client_name, ssl)
      {
        hosts: [
          {
            login: login,
            passcode: pass,
            host: "#{host}",
            port: 61613,
            ssl: ssl
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

    def verify_connection!
      unless @client.open?
        raise ConnectionError.new("Connection failed!!")
      end
      if @client.connection_frame.command == Stomp::CMD_ERROR
        raise ConnectionError.new("Connection error: #{@connection.connection_frame.body}")
      end
    end

    def msg_destination
      "/topic/#{@topic}.>"
    end

    def msg_headers
      {
        "ack": "client-individual",
        # without persistent, suppress_content_length and content-type the queue truncates messages to 256 chars
        "persistent": true,
        "suppress_content_length": true,
        "content-type": "application/json"
      }
    end
end
