# frozen_string_literal: true

class Ams::SubscribeAllJob < ApplicationJob
  queue_as :ams_subscriber

  # New pull every 3 minutes, so retry must be low
  sidekiq_options retry: 2

  def perform
    config = Rails.application.config_for(:ams)

    config.topics.each do |topic|
      subscription_name = [config.subscription_prefix.presence, topic].compact.join("-")
      Ams::SubscribeJob.perform_later(subscription_name)
    end
  end
end
