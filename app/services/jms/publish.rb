# frozen_string_literal: true

require "nori"

class Jms::Publish
  def initialize(message)
    @message = message
    @logger = Logger.new(logger_path)
  end

  def call
    unless @message&.respond_to?(:to_json)
      raise ArgumentError.new("Message must have a :to_json method, passed: #{@message}")
    end

    if publisher_disabled?
      @logger.info("Publisher disabled, ignoring message: #{@message}")
      return
    end

    @publisher_instance = publisher
    Jms::DoPublish.new(@message.to_json, @publisher_instance, @logger).call
  ensure
    finalize!
  end

  private
    def logger_path
      ENV["MP_STOMP_PUBLISHER_LOGGER_PATH"] || "#{Rails.root}/log/jms.publisher.log"
    end

    def publisher_disabled?
      ENV["MP_STOMP_PUBLISHER_ENABLED"] != "true"
    end

    def publisher
      stomp_config = Mp::Application.config_for(:stomp_publisher)

      Jms::Publisher.new(stomp_config["topic"],
                         stomp_config["login"],
                         stomp_config["password"],
                         stomp_config["host"],
                         stomp_config["client-name"],
                         stomp_config["ssl-enabled"],
                         @logger)
    end

    def finalize!
      close_publisher!
      @logger.close
    end

    def close_publisher!
      @publisher_instance&.close
    rescue Error => e
      @logger.warn("Cannot close publisher #{e}")
      Sentry.capture_exception(e)
    end
end
