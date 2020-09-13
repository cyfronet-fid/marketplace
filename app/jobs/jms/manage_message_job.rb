# frozen_string_literal: true

require "nori"

class Jms::ManageMessageJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(message, eic_base_url, logger)
    Jms::ManageMessage.new(message, eic_base_url, logger)
  end
end
