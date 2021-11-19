# frozen_string_literal: true

require "sentry-ruby"

class Jms::PublishJob < ApplicationJob
  queue_as :pc_publisher

  rescue_from ArgumentError, Jms::Publisher::ConnectionError, Stomp::Error do |e|
    logger.warn("Exception occurred: #{e}")
    Sentry.capture_exception(e)
  end

  def perform(message)
    Jms::Publish.new(message).call
  end
end
