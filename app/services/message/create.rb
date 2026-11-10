# frozen_string_literal: true

class Message::Create < ApplicationService
  def initialize(message)
    super()
    @message = message
  end

  def call
    if @message.save
      ActiveRecord.after_all_transactions_commit { Message::RegisterMessageJob.perform_later(@message) }
      true
    end
  end
end
