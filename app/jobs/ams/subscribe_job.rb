# frozen_string_literal: true

class Ams::SubscribeJob < ApplicationJob
  queue_as :ams_subscriber

  # New pull every 3 minutes, so retry must be low
  sidekiq_options retry: 2

  def perform(subscription_name)
    Ams::Subscribe.call(subscription_name)
  end
end
