# frozen_string_literal: true

class Message::Update
  def initialize(message, params)
    @message = message
    @params = params
  end

  def call
    if @offer.update(@params)
      Message::RegisterMessageJob.perform_later(@message)
      true
    end
  end
end
