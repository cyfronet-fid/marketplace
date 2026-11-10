# frozen_string_literal: true

class Jms::ManageMessageJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(message, logger)
    Jms::ManageMessage.call(message, logger)
  end
end
