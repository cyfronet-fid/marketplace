# frozen_string_literal: true

class Trigger::Call
  def initialize(trigger)
    @trigger = trigger
  end

  def call
    Unirest.public_send(@trigger.method, @trigger.url)
  end
end
