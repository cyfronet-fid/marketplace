# frozen_string_literal: true

require "sentry-ruby"

class Jms::PublishJob < ApplicationJob
  queue_as :pc_publisher

  # stomp gem doesn't use a common custom subclass for its Errors, instead it's necessary
  # to catch RuntimeError to handle them all.
  rescue_from ArgumentError, Jms::Publisher::ConnectionError, RuntimeError do |e|
    logger.warn("Exception occurred: #{e}")
    Sentry.capture_exception(e)
  end

  def perform(message, destination = nil)
    Jms::Publish.new(message, destination).call
  end
end
