# frozen_string_literal: true

require "nori"

class Jms::DoPublish
  def initialize(serialized_message, publisher, logger)
    @serialized_message = serialized_message
    @publisher = publisher
    @logger = logger
  end

  def call
    @publisher.publish(@serialized_message)
    @logger.info("Published message #{@serialized_message}")
  rescue Exception => e
    @logger.warn("Exception when publishing a message: #{@serialized_message}, #{e}")
    Sentry.capture_exception(e)
  end
end
