# frozen_string_literal: true

class Message::Create
  def initialize(message)
    @message = message
  end

  def call
    if @message.save
      Message::RegisterMessageJob.perform_later(@message)
      true
    end
  end
end
