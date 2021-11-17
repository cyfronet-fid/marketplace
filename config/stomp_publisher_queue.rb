# frozen_string_literal: true

module Config
  class StompPublisherQueue
    def initialize
      @logger = Logger.new(ENV("MP_STOMP_LOGGER_PATH") || "#{Rails.root}/log/jms.log")
      $stdout.sync = true
    end

    attr_reader :topic,
                string,
                default: ENV["MP_STOMP_PUBLISHER_TOPIC"] ||
                  Rails.application.credentials.stomp_publisher.dig(:topic) ||
                  "''"
    attr_reader :logger, Logger
  end
end
