# frozen_string_literal: true

module Ams
  class DecodeMessage
    include Callable

    def initialize(message)
      @message = message
    end

    def call
      decoded = Base64.decode64(encoded_value)

      message_copy = message.dup
      message_copy["data"] = JSON.parse(decoded)

      message_copy
    rescue JSON::ParserError => e
      Ams::Logger.error("Failed to decode AMS message: #{e.message}")

      message
    end

    private

    attr_reader :message

    def encoded_value
      message.dig("message", "data").presence ||
        message["data"].presence ||
        message["body"].presence ||
        ""
    end
  end
end
