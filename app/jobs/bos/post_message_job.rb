# frozen_string_literal: true

class Bos::PostMessageJob < ApplicationJob
  include BosRetryable

  def perform(message)
    Bos::Client.new.create_message(message) if message.question? && message.project_item.present?
  end
end
