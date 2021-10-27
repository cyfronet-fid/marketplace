# frozen_string_literal: true

class Message::Create
  def initialize(message)
    @message = message
  end

  def call
    return unless @message.save

    Message::RegisterMessageJob.perform_later(@message)
    true
  end
end
