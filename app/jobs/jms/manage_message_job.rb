# frozen_string_literal: true

class Jms::ManageMessageJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(message, eosc_registry_base_url, logger)
    Jms::ManageMessage.new(message, eosc_registry_base_url, logger)
  end
end
