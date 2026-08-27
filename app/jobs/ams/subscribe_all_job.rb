# frozen_string_literal: true

class Ams::SubscribeAllJob < ApplicationJob
  queue_as :ams_subscriber

  def perform
    config = Rails.application.config_for(:ams)

    config.topics.each do |topic|
      subscription_name = [config.subscription_prefix, topic].compact.join("-")
      Ams::SubscribeJob.perform_later(subscription_name)
    end
  end
end
