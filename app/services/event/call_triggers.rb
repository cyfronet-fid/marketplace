# frozen_string_literal: true

class Event::CallTriggers
  def initialize(event)
    @event = event
  end

  def call
    @event.omses.each { |oms| OMS::CallTriggerJob.perform_later(oms) }
  end
end
